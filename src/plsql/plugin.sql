function render 
  ( p_dynamic_action in apex_plugin.t_dynamic_action
  , p_plugin         in apex_plugin.t_plugin )
return apex_plugin.t_dynamic_action_render_result
as
    l_result     apex_plugin.t_dynamic_action_render_result;
begin
    if apex_application.g_debug then
        apex_plugin_util.debug_dynamic_action(p_plugin         => p_plugin,
                                              p_dynamic_action => p_dynamic_action);
    end if;    

    apex_javascript.add_library(
        p_name      => 'ig-serversidelogic',
        p_check_to_add_minified => true,
        --p_directory => '#WORKSPACE_FILES#javascript/',
        p_directory => p_plugin.file_prefix || 'js/',
        p_version   => NULL
    );    

    l_result.javascript_function := 'lib4x.axt.ig.serverSideLogic._execute';
    l_result.ajax_identifier     := apex_plugin.get_ajax_identifier;
    l_result.attribute_01        := p_dynamic_action.attribute_01;  -- execution scope
    -- attribute 02 is the pl/sql block; no need to send to the client
    -- attribute 03 removed
    l_result.attribute_04        := p_dynamic_action.attribute_04;  -- page items to submit
    l_result.attribute_05        := p_dynamic_action.attribute_05;  -- suppress change events
    
    return l_result;
end render;

function ajax
    ( p_dynamic_action in apex_plugin.t_dynamic_action
    , p_plugin         in apex_plugin.t_plugin
    )
return apex_plugin.t_dynamic_action_ajax_result
is
    l_result            apex_plugin.t_dynamic_action_ajax_result;
    l_json              json_object_t;  -- request/response
    l_json_rows         json_array_t;
    l_rows_arr_idx      pls_integer;
    l_obj               json_object_t;      
    l_json_row          json_object_t;    
    l_json_old          json_object_t;
    l_json_new          json_object_t;
    l_json_new_orig     json_object_t;  -- copy of new row which will become old row
    l_json_meta         json_object_t;
    l_json_meta_fields  json_object_t;    
    l_json_meta_field   json_object_t;
    type t_set is table of boolean index by varchar2(100);
    l_multiple          t_set;          -- set of fields enabling multiple values
    l_row_status        varchar2(1);    -- 'C' or 'U' 
    l_directive         varchar2(30);
    l_sql_parameters    apex_exec.t_parameters;  
    l_key               varchar2(200);
    l_key_old           varchar2(200);
    l_key_changed       varchar2(200);
    l_value             varchar2(32767);  
    l_value_old         varchar2(32767);     
    l_value_new         varchar2(32767);              
    l_out_value         varchar2(32767);
    l_binds             sys.dbms_sql.varchar2_table;
    l_plsql_code        clob;
    l_skip              boolean;
    l_has_error         boolean;
    l_prefix            varchar2(6) := 'LIB4X$';

    -- is_attr_bind: check if the bind name reflects an attribute bind like LIB4X$NAME_OLD, LIB4X$JOB_DISPLAY, LIB4X$SAL_CHANGED, LIB4X$STATUS_ERROR_MSG
    function is_attr_bind(p_key varchar2, p_attr_name varchar2)
    return boolean
    is
    begin
        return (length(p_key) > (length(l_prefix) + length(p_attr_name)+1)) and substr(p_key, 1, length(l_prefix)) = l_prefix and substr(p_key, -(length(p_attr_name)+1)) = '_' || p_attr_name;
    end is_attr_bind;

    -- get_row_value: get row value as a scalar value
    function get_row_value(l_row json_object_t, l_key varchar2)
    return varchar2
    is
    begin
        if l_row.get(l_key).is_Object() then
            l_obj := l_row.get_Object(l_key);
            if l_obj.get('v').is_Array() then
                l_value := l_obj.get_array('v').to_string;
            else
                l_value := l_obj.get_string('v');
            end if;
        else
            l_value := l_row.get_string(l_key);
        end if;   
        return l_value;
    end get_row_value;

begin
    l_json := json_object_t.parse(apex_application.g_clob_01);      -- request JSON object
    l_json_rows := l_json.get_Array('rows');
    -- iterate all rows
    for l_rows_arr_idx in 0 .. l_json_rows.get_size - 1 loop
        l_json_row := TREAT (l_json_rows.get(l_rows_arr_idx) AS json_object_t);
        -- prevent logging sensitive info
        /*if (l_json_row.get('recordId').is_array()) then
            apex_debug.message('Processing record id: ' || l_json_row.get_array('recordId').to_string);
        else
            apex_debug.message('Processing record id: ' || l_json_row.get_string('recordId'));
        end if;*/
        if l_json_row.has('directive') then
            l_directive := l_json_row.get_string('directive');
        else
            l_directive := '';
        end if;
        l_json_old := l_json_row.get_object('oldRow');
        l_json_new := l_json_row.get_object('newRow');
        l_json_new_orig := l_json_new.clone; -- preserve original newRow
        l_json_meta := l_json_row.get_Object('meta'); 
        l_json_meta_fields := l_json_meta.get_Object('fields'); 
        l_row_status := l_json_meta.get_string('rowStatus');
        l_plsql_code := p_dynamic_action.attribute_02;
        l_binds := wwv_flow_utilities.get_binds(l_plsql_code);  -- distill binds from pl/sql block

        /*for i in 1 .. l_binds.count loop
            l_key := l_binds(i);
            apex_debug.message('Bind key: ' || l_key);
        end loop;*/

        -- substitute bind variables
        -- APEX_EXEC only accepts string values
        l_sql_parameters := apex_exec.c_empty_parameters;
        for i in 1 .. l_binds.count loop
            l_key := SUBSTR(l_binds(i), 2);    -- without ':'
            if is_attr_bind(l_key, 'OLD') then
                l_key_old := substr(l_key, 1, LENGTH(l_key) - 4);
                l_key_old := substr(l_key_old, length(l_prefix) + 1);
                if l_json_old.has(l_key_old) then
                    l_value := get_row_value(l_json_old, l_key_old);
                else 
                    l_value := null;        -- using empty string would also result in null for out value
                end if;    
            elsif is_attr_bind(l_key, 'CHANGED') then
                l_key_changed := substr(l_key, 1, LENGTH(l_key) - 8);
                l_key_changed := substr(l_key_changed, length(l_prefix) + 1);            
                l_value_old :=  get_row_value(l_json_old, l_key_changed);
                l_value_new :=  get_row_value(l_json_new, l_key_changed);
                -- '' <> 'some value' will result in null! so applying coalesce construct
                if coalesce(l_value_new, chr(0)) <> coalesce(l_value_old, chr(0)) then
                    l_value := 'Y';
                else
                    l_value := 'N';
                end if;
            else 
                if (l_key = 'LIB4X$ROW_STATUS') then
                    l_value := l_row_status;   
                elsif (l_key = 'LIB4X$DIRECTIVE') then
                    l_value := l_directive;
                elsif l_json_new.has(l_key) then
                    if l_json_new.get(l_key).is_Object() then
                        l_obj := l_json_new.get_Object(l_key);
                        if l_obj.get('v').is_Array() then
                            l_value := l_obj.get_array('v').to_string;
                            l_multiple(l_key) := true;
                        else
                            l_value := l_obj.get_string('v');
                        end if;
                    else
                        l_value := l_json_new.get_string(l_key);
                    end if;                    
                else 
                    l_value := apex_session_state.get_varchar2(l_key);  -- default situation: assume an item in session state eg a page item from items to submit
                end if;
            end if;
            --apex_debug.message('Input l_key: ' || l_key);
            --apex_debug.message('Input l_value: ' || l_value);
            apex_exec.add_parameter(
                p_parameters => l_sql_parameters,
                p_name       => l_key,
                p_value      => l_value
            );
        end loop;      

        -- execute the anonymous pl/sql block
        apex_exec.execute_plsql(
            p_plsql_code      => l_plsql_code,
            p_auto_bind_items => false,     -- can not be set to true! See api doc.
            p_sql_parameters  => l_sql_parameters ); 

        -- extract relevant binds
        for i in 1 .. l_binds.count loop
            l_key := SUBSTR(l_binds(i), 2);   
            if (l_json_new.has(l_key) or is_attr_bind(l_key, 'DISPLAY') or is_attr_bind(l_key, 'ERROR_MSG') or (l_key = 'LIB4X$ERROR_MSG')) then                
                l_out_value := apex_exec.get_parameter_varchar2( 
                    p_parameters => l_sql_parameters,
                    p_name       => l_key               
                );
                if (l_out_value is null) then
                    l_out_value := '';
                end if;
                if l_key = 'LIB4X$ERROR_MSG' then
                    l_json_meta.put('error', TRUE);
                    l_json_meta.put('message', l_out_value);
                elsif is_attr_bind(l_key, 'ERROR_MSG') then
                    l_key := substr(l_key, 1, LENGTH(l_key) - 10);
                    l_key := substr(l_key, length(l_prefix) + 1);  
                    l_json_meta_field := l_json_meta_fields.get_Object(l_key);
                    l_has_error := nvl(length(l_out_value), 0) > 0;
                    l_json_meta_field.put('error', l_has_error);
                    l_json_meta_field.put('message', l_out_value);    
                elsif is_attr_bind(l_key, 'DISPLAY') then   
                    l_key := substr(l_key, 1, LENGTH(l_key) - 8);
                    l_key := substr(l_key, length(l_prefix) + 1);
                    -- l_key entry should be a v/d object
                    if l_json_new.get(l_key).is_object() then
                        l_obj := l_json_new.get_object(l_key);
                        l_obj.put('d', l_out_value);                            
                    end if;
                else
                    if l_json_new.get(l_key).is_Object() then
                        l_obj := l_json_new.get_object(l_key);
                        if l_multiple.exists(l_key) then
                            l_obj.put('v', json_array_t.parse(l_out_value));
                        else
                            l_obj.put('v', l_out_value);
                        end if;                         
                    else
                        l_json_new.put(l_key, l_out_value); 
                    end if;
                end if;  
                --apex_debug.message('Output l_key: ' || l_key);
                --apex_debug.message('Output l_value: ' || l_out_value);                    
            end if;      
        end loop;  
        l_json_row.put('oldRow', l_json_new_orig);      -- original new row becomes old row
    end loop;    
    --wwv_flow_utilities.pause(2);
    apex_json.initialize_output;
    apex_json.open_object;
    apex_json.write('status', 'success');  
    apex_json.write_raw('data', l_json.to_clob);       -- write_raw method able to handle large data
    apex_json.close_all;    
    return l_result;
exception when others then
    rollback;
    apex_json.initialize_output;
    apex_json.open_object;
    apex_json.write('status', 'error');
    apex_json.open_object('errorDetails');
    apex_json.write('code', apex_escape.html(SQLCODE));
    apex_json.write('message', apex_escape.html(SQLERRM));   
    apex_json.write('messageText', apex_escape.html(substr(SQLERRM, instr(SQLERRM, ':') + 2)));      
    apex_json.close_all;
    return l_result;     
end ajax;
