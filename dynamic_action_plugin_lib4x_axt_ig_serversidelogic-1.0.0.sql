prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2024.11.30'
,p_release=>'24.2.0'
,p_default_workspace_id=>17062793957969100
,p_default_application_id=>138
,p_default_id_offset=>17513279999319301
,p_default_owner=>'CMF'
);
end;
/
 
prompt APPLICATION 138 - PKX
--
-- Application Export:
--   Application:     138
--   Name:            PKX
--   Date and Time:   17:51 Thursday May 7, 2026
--   Exported By:     KAREL
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 48174220830181978
--   Manifest End
--   Version:         24.2.0
--   Instance ID:     800104173856312
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/dynamic_action/lib4x_axt_ig_serversidelogic
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(48174220830181978)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'LIB4X.AXT.IG.SERVERSIDELOGIC'
,p_display_name=>'LIB4X - Execute Server-Side IG Row Logic'
,p_category=>'EXECUTE'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function render ',
'  ( p_dynamic_action in apex_plugin.t_dynamic_action',
'  , p_plugin         in apex_plugin.t_plugin )',
'return apex_plugin.t_dynamic_action_render_result',
'as',
'    l_result     apex_plugin.t_dynamic_action_render_result;',
'begin',
'    if apex_application.g_debug then',
'        apex_plugin_util.debug_dynamic_action(p_plugin         => p_plugin,',
'                                              p_dynamic_action => p_dynamic_action);',
'    end if;    ',
'',
'    apex_javascript.add_library(',
'        p_name      => ''ig-serversidelogic'',',
'        p_check_to_add_minified => true,',
'        --p_directory => ''#WORKSPACE_FILES#javascript/'',',
'        p_directory => p_plugin.file_prefix || ''js/'',',
'        p_version   => NULL',
'    );    ',
'',
'    l_result.javascript_function := ''lib4x.axt.ig.serverSideLogic._execute'';',
'    l_result.ajax_identifier     := apex_plugin.get_ajax_identifier;',
'    l_result.attribute_01        := p_dynamic_action.attribute_01;  -- execution scope',
'    -- attribute 02 is the pl/sql block; no need to send to the client',
'    -- attribute 03 removed',
'    l_result.attribute_04        := p_dynamic_action.attribute_04;  -- page items to submit',
'    l_result.attribute_05        := p_dynamic_action.attribute_05;  -- suppress change events',
'    ',
'    return l_result;',
'end render;',
'',
'function ajax',
'    ( p_dynamic_action in apex_plugin.t_dynamic_action',
'    , p_plugin         in apex_plugin.t_plugin',
'    )',
'return apex_plugin.t_dynamic_action_ajax_result',
'is',
'    l_result            apex_plugin.t_dynamic_action_ajax_result;',
'    l_json              json_object_t;  -- request/response',
'    l_json_rows         json_array_t;',
'    l_rows_arr_idx      pls_integer;',
'    l_obj               json_object_t;      ',
'    l_json_row          json_object_t;    ',
'    l_json_old          json_object_t;',
'    l_json_new          json_object_t;',
'    l_json_new_orig     json_object_t;  -- copy of new row which will become old row',
'    l_json_meta         json_object_t;',
'    l_json_meta_fields  json_object_t;    ',
'    l_json_meta_field   json_object_t;',
'    type t_set is table of boolean index by varchar2(100);',
'    l_multiple          t_set;          -- set of fields enabling multiple values',
'    l_row_status        varchar2(1);    -- ''C'' or ''U'' ',
'    l_directive         varchar2(30);',
'    l_sql_parameters    apex_exec.t_parameters;  ',
'    l_key               varchar2(200);',
'    l_key_old           varchar2(200);',
'    l_key_changed       varchar2(200);',
'    l_value             varchar2(32767);  ',
'    l_value_old         varchar2(32767);     ',
'    l_value_new         varchar2(32767);              ',
'    l_out_value         varchar2(32767);',
'    l_binds             sys.dbms_sql.varchar2_table;',
'    l_plsql_code        clob;',
'    l_skip              boolean;',
'    l_has_error         boolean;',
'    l_prefix            varchar2(6) := ''LIB4X$'';',
'',
'    -- is_attr_bind: check if the bind name reflects an attribute bind like LIB4X$NAME_OLD, LIB4X$JOB_DISPLAY, LIB4X$SAL_CHANGED, LIB4X$STATUS_ERROR_MSG',
'    function is_attr_bind(p_key varchar2, p_attr_name varchar2)',
'    return boolean',
'    is',
'    begin',
'        return (length(p_key) > (length(l_prefix) + length(p_attr_name)+1)) and substr(p_key, 1, length(l_prefix)) = l_prefix and substr(p_key, -(length(p_attr_name)+1)) = ''_'' || p_attr_name;',
'    end is_attr_bind;',
'',
'    -- get_row_value: get row value as a scalar value',
'    function get_row_value(l_row json_object_t, l_key varchar2)',
'    return varchar2',
'    is',
'    begin',
'        if l_row.get(l_key).is_Object() then',
'            l_obj := l_row.get_Object(l_key);',
'            if l_obj.get(''v'').is_Array() then',
'                l_value := l_obj.get_array(''v'').to_string;',
'            else',
'                l_value := l_obj.get_string(''v'');',
'            end if;',
'        else',
'            l_value := l_row.get_string(l_key);',
'        end if;   ',
'        return l_value;',
'    end get_row_value;',
'',
'begin',
'    l_json := json_object_t.parse(apex_application.g_clob_01);      -- request JSON object',
'    l_json_rows := l_json.get_Array(''rows'');',
'    -- iterate all rows',
'    for l_rows_arr_idx in 0 .. l_json_rows.get_size - 1 loop',
'        l_json_row := TREAT (l_json_rows.get(l_rows_arr_idx) AS json_object_t);',
'        -- prevent logging sensitive info',
'        /*if (l_json_row.get(''recordId'').is_array()) then',
'            apex_debug.message(''Processing record id: '' || l_json_row.get_array(''recordId'').to_string);',
'        else',
'            apex_debug.message(''Processing record id: '' || l_json_row.get_string(''recordId''));',
'        end if;*/',
'        if l_json_row.has(''directive'') then',
'            l_directive := l_json_row.get_string(''directive'');',
'        else',
'            l_directive := '''';',
'        end if;',
'        l_json_old := l_json_row.get_object(''oldRow'');',
'        l_json_new := l_json_row.get_object(''newRow'');',
'        l_json_new_orig := l_json_new.clone; -- preserve original newRow',
'        l_json_meta := l_json_row.get_Object(''meta''); ',
'        l_json_meta_fields := l_json_meta.get_Object(''fields''); ',
'        l_row_status := l_json_meta.get_string(''rowStatus'');',
'        l_plsql_code := p_dynamic_action.attribute_02;',
'        l_binds := wwv_flow_utilities.get_binds(l_plsql_code);  -- distill binds from pl/sql block',
'',
'        /*for i in 1 .. l_binds.count loop',
'            l_key := l_binds(i);',
'            apex_debug.message(''Bind key: '' || l_key);',
'        end loop;*/',
'',
'        -- substitute bind variables',
'        -- APEX_EXEC only accepts string values',
'        l_sql_parameters := apex_exec.c_empty_parameters;',
'        for i in 1 .. l_binds.count loop',
'            l_key := SUBSTR(l_binds(i), 2);    -- without '':''',
'            if is_attr_bind(l_key, ''OLD'') then',
'                l_key_old := substr(l_key, 1, LENGTH(l_key) - 4);',
'                l_key_old := substr(l_key_old, length(l_prefix) + 1);',
'                if l_json_old.has(l_key_old) then',
'                    l_value := get_row_value(l_json_old, l_key_old);',
'                else ',
'                    l_value := null;        -- using empty string would also result in null for out value',
'                end if;    ',
'            elsif is_attr_bind(l_key, ''CHANGED'') then',
'                l_key_changed := substr(l_key, 1, LENGTH(l_key) - 8);',
'                l_key_changed := substr(l_key_changed, length(l_prefix) + 1);            ',
'                l_value_old :=  get_row_value(l_json_old, l_key_changed);',
'                l_value_new :=  get_row_value(l_json_new, l_key_changed);',
'                -- '''' <> ''some value'' will result in null! so applying coalesce construct',
'                if coalesce(l_value_new, chr(0)) <> coalesce(l_value_old, chr(0)) then',
'                    l_value := ''Y'';',
'                else',
'                    l_value := ''N'';',
'                end if;',
'            else ',
'                if (l_key = ''LIB4X$ROW_STATUS'') then',
'                    l_value := l_row_status;   ',
'                elsif (l_key = ''LIB4X$DIRECTIVE'') then',
'                    l_value := l_directive;',
'                elsif l_json_new.has(l_key) then',
'                    if l_json_new.get(l_key).is_Object() then',
'                        l_obj := l_json_new.get_Object(l_key);',
'                        if l_obj.get(''v'').is_Array() then',
'                            l_value := l_obj.get_array(''v'').to_string;',
'                            l_multiple(l_key) := true;',
'                        else',
'                            l_value := l_obj.get_string(''v'');',
'                        end if;',
'                    else',
'                        l_value := l_json_new.get_string(l_key);',
'                    end if;                    ',
'                else ',
'                    l_value := apex_session_state.get_varchar2(l_key);  -- default situation: assume an item in session state eg a page item from items to submit',
'                end if;',
'            end if;',
'            --apex_debug.message(''Input l_key: '' || l_key);',
'            --apex_debug.message(''Input l_value: '' || l_value);',
'            apex_exec.add_parameter(',
'                p_parameters => l_sql_parameters,',
'                p_name       => l_key,',
'                p_value      => l_value',
'            );',
'        end loop;      ',
'',
'        -- execute the anonymous pl/sql block',
'        apex_exec.execute_plsql(',
'            p_plsql_code      => l_plsql_code,',
'            p_auto_bind_items => false,     -- can not be set to true! See api doc.',
'            p_sql_parameters  => l_sql_parameters ); ',
'',
'        -- extract relevant binds',
'        for i in 1 .. l_binds.count loop',
'            l_key := SUBSTR(l_binds(i), 2);   ',
'            if (l_json_new.has(l_key) or is_attr_bind(l_key, ''DISPLAY'') or is_attr_bind(l_key, ''ERROR_MSG'') or (l_key = ''LIB4X$ERROR_MSG'')) then                ',
'                l_out_value := apex_exec.get_parameter_varchar2( ',
'                    p_parameters => l_sql_parameters,',
'                    p_name       => l_key               ',
'                );',
'                if (l_out_value is null) then',
'                    l_out_value := '''';',
'                end if;',
'                if l_key = ''LIB4X$ERROR_MSG'' then',
'                    l_json_meta.put(''error'', TRUE);',
'                    l_json_meta.put(''message'', l_out_value);',
'                elsif is_attr_bind(l_key, ''ERROR_MSG'') then',
'                    l_key := substr(l_key, 1, LENGTH(l_key) - 10);',
'                    l_key := substr(l_key, length(l_prefix) + 1);  ',
'                    l_json_meta_field := l_json_meta_fields.get_Object(l_key);',
'                    l_has_error := nvl(length(l_out_value), 0) > 0;',
'                    l_json_meta_field.put(''error'', l_has_error);',
'                    l_json_meta_field.put(''message'', l_out_value);    ',
'                elsif is_attr_bind(l_key, ''DISPLAY'') then   ',
'                    l_key := substr(l_key, 1, LENGTH(l_key) - 8);',
'                    l_key := substr(l_key, length(l_prefix) + 1);',
'                    -- l_key entry should be a v/d object',
'                    if l_json_new.get(l_key).is_object() then',
'                        l_obj := l_json_new.get_object(l_key);',
'                        l_obj.put(''d'', l_out_value);                            ',
'                    end if;',
'                else',
'                    if l_json_new.get(l_key).is_Object() then',
'                        l_obj := l_json_new.get_object(l_key);',
'                        if l_multiple.exists(l_key) then',
'                            l_obj.put(''v'', json_array_t.parse(l_out_value));',
'                        else',
'                            l_obj.put(''v'', l_out_value);',
'                        end if;                         ',
'                    else',
'                        l_json_new.put(l_key, l_out_value); ',
'                    end if;',
'                end if;  ',
'                --apex_debug.message(''Output l_key: '' || l_key);',
'                --apex_debug.message(''Output l_value: '' || l_out_value);                    ',
'            end if;      ',
'        end loop;  ',
'        l_json_row.put(''oldRow'', l_json_new_orig);      -- original new row becomes old row',
'    end loop;    ',
'    --wwv_flow_utilities.pause(2);',
'    apex_json.initialize_output;',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''success'');  ',
'    apex_json.write_raw(''data'', l_json.to_clob);       -- write_raw method able to handle large data',
'    apex_json.close_all;    ',
'    return l_result;',
'exception when others then',
'    rollback;',
'    apex_json.initialize_output;',
'    apex_json.open_object;',
'    apex_json.write(''status'', ''error'');',
'    apex_json.open_object(''errorDetails'');',
'    apex_json.write(''code'', apex_escape.html(SQLCODE));',
'    apex_json.write(''message'', apex_escape.html(SQLERRM));   ',
'    apex_json.write(''messageText'', apex_escape.html(substr(SQLERRM, instr(SQLERRM, '':'') + 2)));      ',
'    apex_json.close_all;',
'    return l_result;     ',
'end ajax;',
''))
,p_api_version=>1
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'REGION:REQUIRED:STOP_EXECUTION_ON_ERROR:WAIT_FOR_RESULT'
,p_substitute_attributes=>true
,p_version_scn=>470413778
,p_subscribe_plugin_settings=>true
,p_help_text=>'Enables to apply IG row logic server side for one or multiple rows, including manipulating column values and setting validation messages.'
,p_version_identifier=>'1.0.0'
,p_about_url=>'https://github.com/kekema/apex-ig-server-side-logic'
,p_files_version=>5
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(48177241383502351)
,p_plugin_id=>wwv_flow_imp.id(48174220830181978)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>20
,p_prompt=>'Execution Scope'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_show_in_wizard=>false
,p_default_value=>'SCOPE_ACTIVE_ROW'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(48177920051508312)
,p_plugin_attribute_id=>wwv_flow_imp.id(48177241383502351)
,p_display_sequence=>10
,p_display_value=>'For Active Row'
,p_return_value=>'SCOPE_ACTIVE_ROW'
,p_help_text=>'Execute the logic only for the currently active row being edited.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(48178337970513945)
,p_plugin_attribute_id=>wwv_flow_imp.id(48177241383502351)
,p_display_sequence=>20
,p_display_value=>'For Created and Modified Rows'
,p_return_value=>'SCOPE_CREATED_MODIFIED'
,p_help_text=>'Execute the logic for all rows that have been created or modified in the Interactive Grid.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(48260272212830665)
,p_plugin_id=>wwv_flow_imp.id(48174220830181978)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>10
,p_prompt=>'PL/SQL Code'
,p_attribute_type=>'PLSQL'
,p_is_required=>true
,p_show_in_wizard=>false
,p_is_translatable=>false
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Specify an execution only PL/SQL anonymous block.</p>',
'',
'<p>Use bind syntax to read or write row values as per the column name, eg: <code>:NAME</code>, <code>:JOB</code>, <code>:ORDER_STATUS</code></p>',
'',
'Special bind variables (read):<br/>',
'<code>:LIB4X$ROW_STATUS</code> : ''C'' for newly created row; ''U'' for updated row.<br/>',
'<code>:LIB4X$DIRECTIVE</code> : when triggering the DA on multiple places, a directive can be feeded via the event data and can be used to steer the pl/sql logic.<br/>',
'<code>:LIB4X$<Column Name>_OLD</code> : value reflecting the value when the code block was executed previously, or the original value.<br/>',
'<code>:LIB4X$<Column Name>_CHANGED</code> : ''Y'' or ''N'' : whether the value has changed as compared to the OLD value.<br/><br/>',
'',
'Special bind variables (write):<br/>',
'<code>:LIB4X$ERROR_MSG</code> : to set any validation message on the row level. Use empty value to unset any existing message.<br/>',
'<code>:LIB4X$<Column Name>_DISPLAY</code> : for LOV type of columns, enabling you to set the display value.<br/>',
'<code>:LIB4X$<Column Name>_ERROR_MSG</code> : to set any validation message on the column level. Use empty value to unset any existing message.<br/>',
'<br/>',
'<p>Values are always as strings. Numbers will be unformatted, eg: "4578.45". Dates are in ISO format as per apex.date.toISOString(), eg: "2026-03-26T13:00:00". This is both read/write.</p>'))
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(49147600616246787)
,p_plugin_id=>wwv_flow_imp.id(48174220830181978)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Page Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_show_in_wizard=>false
,p_is_translatable=>false
,p_help_text=>'Enabling any page item values being available in your PL/SQL block.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(50833025999207326)
,p_plugin_id=>wwv_flow_imp.id(48174220830181978)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Suppress Change Events'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_show_in_wizard=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_imp.id(48177241383502351)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'SCOPE_ACTIVE_ROW'
,p_help_text=>'When changed value(s) are returned from the server, they are set on the column items (Execution Scope: ''For Active Row''). The default behavior in APEX is to fire change events when setting those item values. By this setting, this can be suppressed, p'
||'reventing any related Dynamic Actions to get triggered. For Execution Scope ''For Created and Modified Rows'', this is not applicable as in that case, the updates are not on column items, but on the model data.'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '77696E646F772E6C69623478203D2077696E646F772E6C69623478207C7C207B7D3B0D0A77696E646F772E6C696234782E617874203D2077696E646F772E6C696234782E617874207C7C207B7D3B0D0A77696E646F772E6C696234782E6178742E696720';
wwv_flow_imp.g_varchar2_table(2) := '3D2077696E646F772E6C696234782E6178742E6967207C7C207B7D3B0D0A0D0A2F2A0D0A202A206C696234782E6178742E69672E736572766572536964654C6F6769630D0A202A20456E61626C657320746F206170706C7920494720726F77206C6F6769';
wwv_flow_imp.g_varchar2_table(3) := '6320736572766572207369646520666F72206F6E65206F72206D756C7469706C6520726F77732C20696E636C7564696E67206D616E6970756C6174696E6720636F6C756D6E2076616C75657320616E642073657474696E672076616C69646174696F6E20';
wwv_flow_imp.g_varchar2_table(4) := '6D657373616765732E0D0A202A20466F72206120726F772C20626F746820616E20276F6C64526F772720616E64206120276E6577526F7727206F626A6563742061726520696E636C7564656420696E2074686520726571756573742C20656E61626C696E';
wwv_flow_imp.g_varchar2_table(5) := '6720746F20636865636B20746865206F6C642076616C7565732061732077656C6C2E20546865206F6C642076616C756573207265666C6563740D0A202A207468652076616C75657320666F72207468652070726576696F75732073657276657220726571';
wwv_flow_imp.g_varchar2_table(6) := '756573742C206F722061726520746865206F726967696E616C2076616C756573206966206E6F2072657175657374207761732073656E64207965742E0D0A202A20416C736F2061206D657461206F626A6563742069732073656E6420666F7220726F7720';
wwv_flow_imp.g_varchar2_table(7) := '6C6576656C20616E64206669656C64206C6576656C206D65746120646174612E2043757272656E746C792C20746865206D657461286669656C647329206172652073656E6420617320656D7074792C207768657265207365727665722D736964652C2065';
wwv_flow_imp.g_varchar2_table(8) := '72726F722064657461696C730D0A202A2063616E20626520616464656420286572726F722F6D657373616765292E0D0A202A2055706F6E20726563656976696E672074686520726573706F6E73652C20616E79206E65772076616C7565732F76616C6964';
wwv_flow_imp.g_varchar2_table(9) := '6174696F6E206D65737361676573206172652070726F63657373656420696E746F20746865206D6F64656C2E200D0A202A2F0D0A6C696234782E6178742E69672E736572766572536964654C6F676963203D202866756E6374696F6E282429207B0D0A0D';
wwv_flow_imp.g_varchar2_table(10) := '0A202020202F2F20657865637574696F6E2073636F70650D0A20202020636F6E73742045535F4143544956455F524F57203D202753434F50455F4143544956455F524F57273B0D0A20202020636F6E73742045535F435245415445445F4D4F4449464945';
wwv_flow_imp.g_varchar2_table(11) := '44203D202753434F50455F435245415445445F4D4F444946494544273B0D0A0D0A202020202F2F206576656E742068616E646C657273206279206967207374617469632069640D0A202020206C65742069675F73736C5F6576656E7448616E646C657273';
wwv_flow_imp.g_varchar2_table(12) := '203D207B7D3B0D0A202020202F2F2072657175657374207365714E6F206279206967207374617469632069640D0A202020206C65742069675F726571756573744E6F203D207B7D3B0D0A0D0A0D0A202020206C6574206D6F64656C4D6F64756C65203D20';
wwv_flow_imp.g_varchar2_table(13) := '2866756E6374696F6E2829207B0D0A0D0A2020202020202020636F6E737420737562736372697074696F6E73203D206E6577205765616B4D617028293B0D0A0D0A20202020202020202F2A0D0A2020202020202020202A2073756273637269626520746F';
wwv_flow_imp.g_varchar2_table(14) := '206D6F64656C206E6F74696669636174696F6E732061732075706F6E20736176652028726566726573685265636F7264732920616E6420756E646F2028726576657274292C0D0A2020202020202020202A20616E79206F6C64526F77206F6E2074686520';
wwv_flow_imp.g_varchar2_table(15) := '7265636F7264206D65746461746120746F2062652072656D6F7665642E200D0A2020202020202020202A206F6C64526F77206265696E67206120637573746F6D2073657474696E67207370656369666963616C6C7920666F72207468697320706C756769';
wwv_flow_imp.g_varchar2_table(16) := '6E20746F200D0A2020202020202020202A206B65657020747261636B206F66207468652070726576696F75736C792073656E6420726F7720746F20746865207365727665722C2061732074686F73652076616C7565732073657276652061730D0A202020';
wwv_flow_imp.g_varchar2_table(17) := '2020202020202A206F6C642076616C756573206F6E20746865206E6578742073657276657220726571756573742E0D0A2020202020202020202A20412073617665206F7220756E646F206D65616E7320612072657365742C20616E6420746865206F6C64';
wwv_flow_imp.g_varchar2_table(18) := '2076616C75657320666F7220746865206E65787420726571756573742077696C6C0D0A2020202020202020202A207374656D2066726F6D20746865206F726967696E616C207265636F7264206173206D61696E7461696E6564206279204150455820696E';
wwv_flow_imp.g_varchar2_table(19) := '20746865206D6F64656C206D657461646174612E0D0A2020202020202020202A2F0D0A202020202020202066756E6374696F6E20656E7375726553756273637269626564286D6F64656C29207B0D0A202020202020202020202020696620282173756273';
wwv_flow_imp.g_varchar2_table(20) := '6372697074696F6E732E686173286D6F64656C2929207B0D0A202020202020202020202020202020206C657420737562203D206D6F64656C2E737562736372696265287B0D0A20202020202020202020202020202020202020206F6E4368616E67653A20';
wwv_flow_imp.g_varchar2_table(21) := '66756E6374696F6E286368616E6765547970652C206368616E676529207B0D0A202020202020202020202020202020202020202020202020696620285B27726566726573685265636F726473272C2027726576657274275D2E696E636C75646573286368';
wwv_flow_imp.g_varchar2_table(22) := '616E67655479706529290D0A2020202020202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020206368616E67652E7265636F7264733F2E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(23) := '7265636F7264297B0D0A20202020202020202020202020202020202020202020202020202020202020206C6574207265636F72644964203D206D6F64656C2E6765745265636F72644964287265636F7264293B0D0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(24) := '20202020202020202020202020202020206C6574207265634D65746164617461203D206D6F64656C2E6765745265636F72644D65746164617461287265636F72644964293B0D0A2020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(25) := '202020696620287265634D657461646174612E6C696234783F2E6F6C64526F77290D0A20202020202020202020202020202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(26) := '20202020202064656C657465207265634D657461646174612E6C696234782E6F6C64526F773B0D0A20202020202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(27) := '2020207D293B0D0A2020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020207D2C0D0A20202020202020202020202020202020202020206F6E44657374726F793A2066756E6374696F6E2829';
wwv_flow_imp.g_varchar2_table(28) := '207B0D0A202020202020202020202020202020202020202020202020737562736372697074696F6E732E64656C657465286D6F64656C293B0D0A20202020202020202020202020202020202020207D0D0A202020202020202020202020202020207D293B';
wwv_flow_imp.g_varchar2_table(29) := '0D0A20202020202020202020202020202020737562736372697074696F6E732E736574286D6F64656C2C20737562293B0D0A2020202020202020202020207D0D0A20202020202020207D0D0A0D0A202020202020202072657475726E207B0D0A20202020';
wwv_flow_imp.g_varchar2_table(30) := '2020202020202020656E73757265537562736372696265643A20656E73757265537562736372696265640D0A20202020202020207D0D0A202020207D2928293B0D0A0D0A202020206C6574206D6F64656C5574696C203D207B2020200D0A202020202020';
wwv_flow_imp.g_varchar2_table(31) := '20202F2F20636F6D706F73652074686520726F77206F626A65637420696E636C7564696E67206F6C64526F772F6E6577526F7720616E64206D657461286669656C6473290D0A20202020202020206765745472616E736665724F626A6563743A2066756E';
wwv_flow_imp.g_varchar2_table(32) := '6374696F6E286D6F64656C2C207265634D657461646174612C20646972656374697665290D0A20202020202020207B0D0A2020202020202020202020206C6574207472616E736665724F626A656374203D207B7D3B0D0A20202020202020202020202074';
wwv_flow_imp.g_varchar2_table(33) := '72616E736665724F626A6563742E7265636F72644964203D206D6F64656C2E6765745265636F72644964287265634D657461646174612E7265636F7264293B0D0A20202020202020202020202069662028646972656374697665290D0A20202020202020';
wwv_flow_imp.g_varchar2_table(34) := '20202020207B0D0A202020202020202020202020202020207472616E736665724F626A6563742E646972656374697665203D206469726563746976653B0D0A2020202020202020202020207D0D0A2020202020202020202020207472616E736665724F62';
wwv_flow_imp.g_varchar2_table(35) := '6A6563740D0A2020202020202020202020207472616E736665724F626A6563742E6D657461203D207B7D3B0D0A2020202020202020202020207472616E736665724F626A6563742E6D6574612E6669656C6473203D207B7D3B0D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(36) := '2020202F2F696620287265634D657461646174612E6F726967696E616C290D0A2020202020202020202020202F2F7B0D0A202020202020202020202020202020207472616E736665724F626A6563742E6E6577526F77203D20746869732E7265636F7264';
wwv_flow_imp.g_varchar2_table(37) := '4172726179546F4F626A656374286D6F64656C2C207265634D657461646174612E7265636F7264293B0D0A202020202020202020202020202020202F2F7472616E736665724F626A6563742E6D6574612E6F726967696E616C203D20746869732E726563';
wwv_flow_imp.g_varchar2_table(38) := '6F72644172726179546F4F626A656374286D6F64656C2C207265634D657461646174612E6F726967696E616C293B0D0A20202020202020202020202020202020696620287265634D657461646174612E6C696234783F2E6F6C64526F77290D0A20202020';
wwv_flow_imp.g_varchar2_table(39) := '2020202020202020202020207B0D0A20202020202020202020202020202020202020207472616E736665724F626A6563742E6F6C64526F77203D207265634D657461646174612E6C696234782E6F6C64526F773B0D0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(40) := '20207D0D0A20202020202020202020202020202020656C73650D0A202020202020202020202020202020207B0D0A20202020202020202020202020202020202020207472616E736665724F626A6563742E6F6C64526F77203D20746869732E7265636F72';
wwv_flow_imp.g_varchar2_table(41) := '644172726179546F4F626A656374286D6F64656C2C207265634D657461646174612E6F726967696E616C203F3F207265634D657461646174612E7265636F7264293B0D0A202020202020202020202020202020207D0D0A2020202020202020202020202F';
wwv_flow_imp.g_varchar2_table(42) := '2F7D0D0A2020202020202020202020202F2A6C65742070726F7073203D205B276572726F72272C20277761726E696E67272C20276D657373616765275D3B0D0A202020202020202020202020666F722028636F6E73742070726F70206F662070726F7073';
wwv_flow_imp.g_varchar2_table(43) := '29207B0D0A202020202020202020202020202020206966202870726F7020696E207265634D6574616461746129207B0D0A20202020202020202020202020202020202020207472616E736665724F626A6563742E6D6574615B70726F705D203D20726563';
wwv_flow_imp.g_varchar2_table(44) := '4D657461646174615B70726F705D3B0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D2A2F0D0A202020202020202020202020696620287265634D657461646174612E696E736572746564290D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(45) := '202020207B0D0A202020202020202020202020202020207472616E736665724F626A6563742E6D6574612E726F77537461747573203D202743273B0D0A2020202020202020202020207D0D0A202020202020202020202020656C73652069662028726563';
wwv_flow_imp.g_varchar2_table(46) := '4D657461646174612E75706461746564290D0A2020202020202020202020207B0D0A202020202020202020202020202020207472616E736665724F626A6563742E6D6574612E726F77537461747573203D202755273B0D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(47) := '7D0D0A2020202020202020202020206C6574206D6F64656C4669656C6473203D206D6F64656C2E6765744F7074696F6E28226669656C647322293B0D0A202020202020202020202020666F722028636F6E7374205B6669656C644E616D652C206D6F6465';
wwv_flow_imp.g_varchar2_table(48) := '6C4669656C645D206F66204F626A6563742E656E7472696573286D6F64656C4669656C647329290D0A2020202020202020202020207B0D0A2020202020202020202020202020202069662028746869732E69735265636F72644669656C64286D6F64656C';
wwv_flow_imp.g_varchar2_table(49) := '2C206D6F64656C4669656C6429290D0A202020202020202020202020202020207B0D0A20202020202020202020202020202020202020202F2F696620287265634D657461646174612E6669656C64733F2E6861734F776E50726F7065727479286669656C';
wwv_flow_imp.g_varchar2_table(50) := '644E616D6529290D0A20202020202020202020202020202020202020202F2F7B0D0A20202020202020202020202020202020202020202F2F202020207472616E736665724F626A6563742E6D6574612E6669656C64735B6669656C644E616D655D203D20';
wwv_flow_imp.g_varchar2_table(51) := '73747275637475726564436C6F6E65287265634D657461646174612E6669656C64735B6669656C644E616D655D293B0D0A20202020202020202020202020202020202020202F2F7D0D0A20202020202020202020202020202020202020202F2F656C7365';
wwv_flow_imp.g_varchar2_table(52) := '0D0A20202020202020202020202020202020202020202F2F7B0D0A2020202020202020202020202020202020202020202020207472616E736665724F626A6563742E6D6574612E6669656C64735B6669656C644E616D655D203D207B7D3B202020202020';
wwv_flow_imp.g_varchar2_table(53) := '2020202F2F2063757272656E746C792C207765206172652073656E64696E67206A75737420656D7074792C20616E64207365727665722D736964652C206572726F722064657461696C732063616E206265207365740D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(54) := '202020202020202F2F7D0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D0D0A20202020202020202020202072657475726E207472616E736665724F626A6563743B0D0A20202020202020207D2C0D0A202020202020';
wwv_flow_imp.g_varchar2_table(55) := '20202F2F20646572697665206120726F77206F626A6563742066726F6D2061206D6F64656C207265636F72642028776869636820697320616E206172726179290D0A20202020202020202F2F20666F72206E756D626572732C20756E666F726D61747465';
wwv_flow_imp.g_varchar2_table(56) := '642076616C756573206172652074616B656E3B20666F72206461746573207468652049534F20646174650D0A20202020202020207265636F72644172726179546F4F626A6563743A2066756E6374696F6E286D6F64656C2C207265636F7264290D0A2020';
wwv_flow_imp.g_varchar2_table(57) := '2020202020207B0D0A2020202020202020202020206C6574207265636F72644F626A656374203D206E756C6C3B0D0A2020202020202020202020206C6574206D6F64656C4669656C6473203D206D6F64656C2E6765744F7074696F6E28226669656C6473';
wwv_flow_imp.g_varchar2_table(58) := '22293B0D0A202020202020202020202020696620287265636F7264202626206D6F64656C4669656C6473290D0A2020202020202020202020207B0D0A202020202020202020202020202020207265636F72644F626A656374203D207B7D3B0D0A20202020';
wwv_flow_imp.g_varchar2_table(59) := '202020202020202020202020666F722028636F6E7374205B6669656C644E616D652C206D6F64656C4669656C645D206F66204F626A6563742E656E7472696573286D6F64656C4669656C647329290D0A202020202020202020202020202020207B20200D';
wwv_flow_imp.g_varchar2_table(60) := '0A202020202020202020202020202020202020202069662028746869732E69735265636F72644669656C64286D6F64656C2C206D6F64656C4669656C6429290D0A20202020202020202020202020202020202020207B0D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(61) := '2020202020202020202020207265636F72644F626A6563745B6669656C644E616D655D203D20746869732E6D6F64656C546F526F7756616C7565286D6F64656C2C207265636F72642C206669656C644E616D65293B0D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(62) := '202020202020207D0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D0D0A20202020202020202020202072657475726E207265636F72644F626A6563743B0D0A20202020202020207D2C202020200D0A202020202020';
wwv_flow_imp.g_varchar2_table(63) := '20206D6F64656C546F526F775363616C617256616C75653A2066756E6374696F6E286D6F64656C2C207265636F72642C2070726F7065727479290D0A20202020202020207B0D0A2020202020202020202020206C65742076616C7565203D20746869732E';
wwv_flow_imp.g_varchar2_table(64) := '6D6F64656C546F526F7756616C7565286D6F64656C2C207265636F72642C2070726F7065727479293B0D0A20202020202020202020202072657475726E207574696C2E6765745363616C617256616C75652876616C7565293B0D0A20202020202020207D';
wwv_flow_imp.g_varchar2_table(65) := '2C0D0A20202020202020202F2F206D6F64656C546F526F7756616C75650D0A20202020202020202F2F206765742076616C756520617320737472696E673B206966206E756D626572206669656C642C207468652076616C75652077696C6C20626520756E';
wwv_flow_imp.g_varchar2_table(66) := '666F726D61747465642C2065672022343537382E3435222E200D0A20202020202020202F2F2064617465732061726520696E2049534F20666F726D61742061732070657220617065782E646174652E746F49534F537472696E6728292C2065673A202232';
wwv_flow_imp.g_varchar2_table(67) := '3032362D30332D32365431333A30303A3030220D0A20202020202020206D6F64656C546F526F7756616C75653A2066756E6374696F6E286D6F64656C2C207265636F72642C2070726F7065727479290D0A20202020202020207B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(68) := '202020206C65742076616C7565203D206D6F64656C2E67657456616C7565287265636F72642C2070726F7065727479293B0D0A2020202020202020202020206966202876616C756520213D206E756C6C20262620747970656F662076616C7565203D3D3D';
wwv_flow_imp.g_varchar2_table(69) := '20276F626A65637427290D0A2020202020202020202020207B0D0A202020202020202020202020202020202F2F206D616B65206120636C6F6E65206173207468652076616C7565206D696768742067657420757064617465642066726F6D207468652063';
wwv_flow_imp.g_varchar2_table(70) := '757272656E742063656C6C0D0A2020202020202020202020202020202076616C7565203D2073747275637475726564436C6F6E652876616C7565293B0D0A2020202020202020202020207D0D0A20202020202020202020202072657475726E2074686973';
wwv_flow_imp.g_varchar2_table(71) := '2E676574556E666F726D617474656456616C75652876616C75652C206D6F64656C2C2070726F7065727479293B0D0A20202020202020207D2C20200D0A2020202020202020676574556E666F726D617474656456616C75653A2066756E6374696F6E2876';
wwv_flow_imp.g_varchar2_table(72) := '616C75652C206D6F64656C2C2070726F7065727479290D0A20202020202020207B0D0A2020202020202020202020206C657420756E666F726D617474656456616C7565203D2076616C75653B0D0A2020202020202020202020206966202876616C756520';
wwv_flow_imp.g_varchar2_table(73) := '213D206E756C6C2026262076616C756520213D3D20272720262620747970656F662076616C756520213D3D20276F626A65637427290D0A2020202020202020202020207B2020202020202020202020200D0A202020202020202020202020202020206C65';
wwv_flow_imp.g_varchar2_table(74) := '74206D6F64656C4669656C6473203D206D6F64656C2E6765744F7074696F6E28276669656C647327293B0D0A202020202020202020202020202020206C6574206D6F64656C4669656C64203D206D6F64656C4669656C64735B70726F70657274795D3B0D';
wwv_flow_imp.g_varchar2_table(75) := '0A202020202020202020202020202020206C6574206461746154797065203D206D6F64656C4669656C642E64617461547970653B0D0A20202020202020202020202020202020696620286461746154797065203D3D20274E554D42455227290D0A202020';
wwv_flow_imp.g_varchar2_table(76) := '202020202020202020202020207B0D0A2020202020202020202020202020202020202020756E666F726D617474656456616C7565203D20537472696E6728617065782E6C6F63616C652E746F4E756D6265722876616C75652C206D6F64656C4669656C64';
wwv_flow_imp.g_varchar2_table(77) := '2E666F726D61744D61736B29293B0D0A202020202020202020202020202020207D0D0A20202020202020202020202020202020656C736520696620286461746154797065203D3D20274441544527290D0A202020202020202020202020202020207B0D0A';
wwv_flow_imp.g_varchar2_table(78) := '2020202020202020202020202020202020202020756E666F726D617474656456616C7565203D2027273B0D0A20202020202020202020202020202020202020207472790D0A20202020202020202020202020202020202020207B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(79) := '20202020202020202020202020202020756E666F726D617474656456616C7565203D20617065782E646174652E70617273652876616C75652C206D6F64656C4669656C642E666F726D61744D61736B293B0D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(80) := '2020207D0D0A20202020202020202020202020202020202020206361746368286572726F7229207B7D3B0D0A202020202020202020202020202020202020202069662028756E666F726D617474656456616C7565290D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(81) := '202020202020207B0D0A2020202020202020202020202020202020202020202020202F2F2044415445207479706520696E204F7261636C6520686173206E6F2074696D657A6F6E6520696E666F2C20736F2077652073656E642070617273656420646174';
wwv_flow_imp.g_varchar2_table(82) := '652061732D69732C2073616D652061732049472069732073656E64696E672075706F6E20736176650D0A202020202020202020202020202020202020202020202020756E666F726D617474656456616C7565203D20617065782E646174652E746F49534F';
wwv_flow_imp.g_varchar2_table(83) := '537472696E6728756E666F726D617474656456616C7565293B2020202F2F2049534F20737472696E6720776974686F75742074696D657A6F6E652E2045673A20323032362D30332D32365431333A30303A30300D0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(84) := '20202020207D0D0A202020202020202020202020202020207D200D0A2020202020202020202020207D0D0A20202020202020202020202072657475726E20756E666F726D617474656456616C75653B20202020202020202020200D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(85) := '7D2C0D0A20202020202020202F2F20726F77546F4D6F64656C56616C75650D0A20202020202020202F2F206E756D626572732077696C6C2067657420666F726D61747465640D0A20202020202020202F2F2064617465732077696C6C207472616E73666F';
wwv_flow_imp.g_varchar2_table(86) := '726D2066726F6D2049534F20666F726D617420746F20646174652061732070657220616E7920666F726D6174206D61736B0D0A2020202020202020726F77546F4D6F64656C56616C75653A2066756E6374696F6E286D6F64656C2C2070726F7065727479';
wwv_flow_imp.g_varchar2_table(87) := '2C2076616C7565290D0A20202020202020207B0D0A2020202020202020202020206C6574206D6F64656C56616C7565203D2076616C75653B0D0A2020202020202020202020206966202876616C756520213D3D20272720262620747970656F662076616C';
wwv_flow_imp.g_varchar2_table(88) := '756520213D3D20276F626A65637427290D0A2020202020202020202020207B0D0A202020202020202020202020202020206C6574206D6F64656C4669656C6473203D206D6F64656C2E6765744F7074696F6E28276669656C647327293B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(89) := '20202020202020202020206C6574206D6F64656C4669656C64203D206D6F64656C4669656C64735B70726F70657274795D3B0D0A202020202020202020202020202020206C6574206461746154797065203D206D6F64656C4669656C642E646174615479';
wwv_flow_imp.g_varchar2_table(90) := '70653B0D0A20202020202020202020202020202020696620286461746154797065203D3D20274E554D42455227290D0A202020202020202020202020202020207B0D0A20202020202020202020202020202020202020206D6F64656C56616C7565203D20';
wwv_flow_imp.g_varchar2_table(91) := '617065782E6C6F63616C652E666F726D61744E756D626572284E756D6265722876616C7565292C206D6F64656C4669656C642E666F726D61744D61736B293B0D0A202020202020202020202020202020207D0D0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(92) := '656C736520696620286461746154797065203D3D20274441544527290D0A202020202020202020202020202020207B0D0A20202020202020202020202020202020202020207472790D0A20202020202020202020202020202020202020207B0D0A202020';
wwv_flow_imp.g_varchar2_table(93) := '2020202020202020202020202020202020202020206C6574206461746556616C7565203D206E657720446174652876616C7565293B0D0A202020202020202020202020202020202020202020202020696620286461746556616C7565290D0A2020202020';
wwv_flow_imp.g_varchar2_table(94) := '202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020206D6F64656C56616C7565203D20617065782E646174652E666F726D6174286461746556616C75652C206D6F64656C4669656C';
wwv_flow_imp.g_varchar2_table(95) := '642E666F726D61744D61736B293B0D0A2020202020202020202020202020202020202020202020207D202020200D0A20202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020206361746368286572726F';
wwv_flow_imp.g_varchar2_table(96) := '72297B7D3B202020202020202020202020202020200D0A202020202020202020202020202020207D202020202020202020202020202020200D0A2020202020202020202020207D0D0A20202020202020202020202072657475726E206D6F64656C56616C';
wwv_flow_imp.g_varchar2_table(97) := '75653B0D0A20202020202020207D2C0D0A202020202020202069735265636F72644669656C643A2066756E6374696F6E286D6F64656C2C206D6F64656C4669656C64290D0A20202020202020207B0D0A20202020202020202020202072657475726E2028';
wwv_flow_imp.g_varchar2_table(98) := '6D6F64656C4669656C642E6861734F776E50726F70657274792827696E6465782729202626206D6F64656C4669656C642E70726F706572747920213D206D6F64656C2E6765744F7074696F6E28276D6574614669656C642729293B200D0A202020202020';
wwv_flow_imp.g_varchar2_table(99) := '20207D2C20202020202020200D0A20202020202020206765744669656C644D657461646174613A2066756E6374696F6E287265634D657461646174612C206669656C644E616D652C2063726561746549664E6F7445786973747329207B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(100) := '202020202020206C657420726573756C74203D206E756C6C3B0D0A202020202020202020202020696620287265634D6574616461746129207B0D0A202020202020202020202020202020206C6574206669656C6473203D207265634D657461646174612E';
wwv_flow_imp.g_varchar2_table(101) := '6669656C6473207C7C202863726561746549664E6F74457869737473203F207265634D657461646174612E6669656C6473203D207B7D203A206E756C6C293B0D0A20202020202020202020202020202020696620286669656C647329207B0D0A20202020';
wwv_flow_imp.g_varchar2_table(102) := '20202020202020202020202020202020726573756C74203D206669656C64735B6669656C644E616D655D207C7C202863726561746549664E6F74457869737473203F206669656C64735B6669656C644E616D655D203D207B7D203A206E756C6C293B0D0A';
wwv_flow_imp.g_varchar2_table(103) := '202020202020202020202020202020207D0D0A2020202020202020202020207D20202020202020202020200D0A20202020202020202020202072657475726E20726573756C743B0D0A20202020202020207D2C0D0A20202020202020206765744669656C';
wwv_flow_imp.g_varchar2_table(104) := '644D65746150726F706572747956616C75653A2066756E6374696F6E287265634D657461646174612C206669656C644E616D652C206D65746150726F706572747929207B0D0A2020202020202020202020206C657420726573756C74203D206E756C6C3B';
wwv_flow_imp.g_varchar2_table(105) := '0D0A2020202020202020202020206C6574206669656C644D65746164617461203D20746869732E6765744669656C644D65746164617461287265634D657461646174612C206669656C644E616D652C2066616C7365293B0D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(106) := '20696620286669656C644D6574616461746129207B0D0A20202020202020202020202020202020726573756C74203D206669656C644D657461646174615B6D65746150726F70657274795D3B0D0A2020202020202020202020207D0D0A20202020202020';
wwv_flow_imp.g_varchar2_table(107) := '202020202072657475726E20726573756C743B0D0A20202020202020207D2C0D0A20202020202020202F2F2041504558206973206F6E6C79206B656570696E6720747261636B206F66207468652061637475616C207265636F726420616E642074686520';
wwv_flow_imp.g_varchar2_table(108) := '6F726967696E616C0D0A20202020202020202F2F20666F722074686520706C7567696E2C20776520616C736F206B65657020747261636B206F66206F6C64526F772C207768696368207265666C656374732074686520726F772061732073656E6420696E';
wwv_flow_imp.g_varchar2_table(109) := '207468652070726576696F757320736572766572207265717565737420202020202020200D0A20202020202020207365744F6C64526F773A2066756E6374696F6E287265636F72644D657461646174612C206F6C64526F77290D0A20202020202020207B';
wwv_flow_imp.g_varchar2_table(110) := '0D0A20202020202020202020202069662028217265636F72644D657461646174612E6C69623478290D0A2020202020202020202020207B0D0A202020202020202020202020202020207265636F72644D657461646174612E6C696234783D207B7D3B0D0A';
wwv_flow_imp.g_varchar2_table(111) := '2020202020202020202020207D0D0A2020202020202020202020207265636F72644D657461646174612E6C696234782E6F6C64526F77203D206F6C64526F773B2020202020202020202020200D0A20202020202020207D20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(112) := '202020202020200D0A202020207D0D0A0D0A202020206C6574207574696C203D207B2020200D0A20202020202020206765745363616C617256616C75653A2066756E6374696F6E2876616C7565290D0A20202020202020207B0D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(113) := '2020206966202876616C756520213D3D206E756C6C20262620747970656F662076616C7565203D3D3D20226F626A656374222026262076616C75652E6861734F776E50726F706572747928202276222029290D0A2020202020202020202020207B0D0A20';
wwv_flow_imp.g_varchar2_table(114) := '20202020202020202020202020202076616C7565203D2076616C75652E763B0D0A202020202020202020202020202020206966202841727261792E697341727261792876616C756529290D0A202020202020202020202020202020207B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(115) := '20202020202020202020202020202076616C7565203D204A534F4E2E737472696E676966792876616C7565293B0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D0D0A20202020202020202020202072657475726E20';
wwv_flow_imp.g_varchar2_table(116) := '76616C75653B0D0A20202020202020207D2C0D0A202020202020202067657444656570416374697665456C656D656E743A2066756E6374696F6E28646F63203D20646F63756D656E7429207B0D0A2020202020202020202020206C657420616374697665';
wwv_flow_imp.g_varchar2_table(117) := '203D20646F632E616374697665456C656D656E743B0D0A2020202020202020202020207768696C652028616374697665202626206163746976652E7461674E616D65203D3D3D2027494652414D452729207B0D0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(118) := '747279207B0D0A20202020202020202020202020202020202020206C657420696E6E6572446F63203D206163746976652E636F6E74656E74446F63756D656E74207C7C206163746976652E636F6E74656E7457696E646F772E646F63756D656E743B0D0A';
wwv_flow_imp.g_varchar2_table(119) := '2020202020202020202020202020202020202020616374697665203D20696E6E6572446F632E616374697665456C656D656E743B0D0A202020202020202020202020202020207D20636174636820286529207B0D0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(120) := '20202020202F2F2043726F73732D6F726967696E20696672616D6520E286922063616E6E6F742061636365737320696E736964650D0A2020202020202020202020202020202020202020627265616B3B0D0A202020202020202020202020202020207D0D';
wwv_flow_imp.g_varchar2_table(121) := '0A2020202020202020202020207D0D0A20202020202020202020202072657475726E206163746976653B0D0A20202020202020207D20202020202020200D0A202020207D3B0D0A0D0A2020202066756E6374696F6E206765744576656E7448616E646C65';
wwv_flow_imp.g_varchar2_table(122) := '7228696753746174696349642C2068616E646C65724E616D65290D0A202020207B0D0A20202020202020206C657420726573756C74203D206E756C6C3B0D0A20202020202020206966202869675F73736C5F6576656E7448616E646C6572732E6861734F';
wwv_flow_imp.g_varchar2_table(123) := '776E50726F7065727479286967537461746963496429290D0A20202020202020207B0D0A2020202020202020202020206C6574206576656E7448616E646C657273203D2069675F73736C5F6576656E7448616E646C6572735B696753746174696349645D';
wwv_flow_imp.g_varchar2_table(124) := '3B0D0A20202020202020202020202069662028747970656F66206576656E7448616E646C6572735B68616E646C65724E616D655D203D3D3D202766756E6374696F6E272920202020200D0A2020202020202020202020207B0D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(125) := '202020202020726573756C74203D206576656E7448616E646C6572735B68616E646C65724E616D655D3B0D0A2020202020202020202020207D2020200D0A20202020202020207D0D0A202020202020202072657475726E20726573756C743B202020200D';
wwv_flow_imp.g_varchar2_table(126) := '0A202020207D0D0A0D0A2020202066756E6374696F6E206669726553534C4576656E7428696753746174696349642C206E616D652C20637478290D0A202020207B0D0A2020202020202020617065782E64656275672E747261636528276C696234782D65';
wwv_flow_imp.g_varchar2_table(127) := '76656E74202849472D53534C293A20272C206E616D652C20637478293B0D0A20202020202020206765744576656E7448616E646C657228696753746174696349642C206E616D65293F2E28637478293B0D0A202020207D202020200D0A0D0A2020202066';
wwv_flow_imp.g_varchar2_table(128) := '756E6374696F6E207365744F7665726C617928696753746174696349642C207472616E73706172656E74290D0A202020207B0D0A20202020202020206C657420637373203D207B706F736974696F6E3A20276162736F6C757465277D3B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(129) := '202020696620287472616E73706172656E7429207B0D0A2020202020202020202020206373735B276261636B67726F756E642D636F6C6F72275D203D2027756E736574273B0D0A20202020202020207D0D0A202020202020202072657475726E20242827';
wwv_flow_imp.g_varchar2_table(130) := '3C64697620636C6173733D22617065785F776169745F6F7665726C6179223E3C2F6469763E27292E63737328637373292E70726570656E64546F282428272327202B206967537461746963496429293B0D0A202020207D202020200D0A0D0A2020202066';
wwv_flow_imp.g_varchar2_table(131) := '756E6374696F6E20636F6D706F7365526571756573744F626A65637428696753746174696349642C206D6F64656C2C20657865637574696F6E53636F70652C20646972656374697665290D0A202020207B0D0A20202020202020206C6574206772696456';
wwv_flow_imp.g_varchar2_table(132) := '696577203D20617065782E726567696F6E2869675374617469634964292E63616C6C2827676574566965777327292E677269643B0D0A20202020202020206C657420726571756573744F626A656374203D207B7D3B0D0A202020202020202069675F7265';
wwv_flow_imp.g_varchar2_table(133) := '71756573744E6F5B696753746174696349645D203D2069675F726571756573744E6F5B696753746174696349645D202B20313B20202020202020200D0A2020202020202020726571756573744F626A6563742E726571756573744E6F203D2069675F7265';
wwv_flow_imp.g_varchar2_table(134) := '71756573744E6F5B696753746174696349645D3B0D0A2020202020202020726571756573744F626A6563742E726F7773203D205B5D3B0D0A20202020202020206C6574206D6F64656C4368616E676573203D205B5D3B0D0A202020202020202069662028';
wwv_flow_imp.g_varchar2_table(135) := '657865637574696F6E53636F7065203D3D2045535F4143544956455F524F57290D0A20202020202020207B0D0A2020202020202020202020206C6574206163746976655265636F72644964203D2067726964566965772E76696577242E67726964282767';
wwv_flow_imp.g_varchar2_table(136) := '65744163746976655265636F7264496427293B200D0A202020202020202020202020696620286163746976655265636F72644964290D0A2020202020202020202020207B0D0A202020202020202020202020202020206C6574207265636F72644D657461';
wwv_flow_imp.g_varchar2_table(137) := '64617461203D206D6F64656C2E6765745265636F72644D65746164617461286163746976655265636F72644964293B0D0A20202020202020202020202020202020696620287265636F72644D65746164617461290D0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(138) := '20207B0D0A20202020202020202020202020202020202020206D6F64656C4368616E6765732E70757368287265636F72644D65746164617461293B0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D0D0A2020202020';
wwv_flow_imp.g_varchar2_table(139) := '2020207D0D0A2020202020202020656C73652069662028657865637574696F6E53636F7065203D3D2045535F435245415445445F4D4F444946494544290D0A20202020202020207B0D0A2020202020202020202020206D6F64656C4368616E676573203D';
wwv_flow_imp.g_varchar2_table(140) := '206D6F64656C2E6765744368616E67657328293B0D0A20202020202020207D0D0A20202020202020206D6F64656C4368616E6765732E666F72456163682866756E6374696F6E287265636F72644D6574616461746129207B0D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(141) := '202069662028217265636F72644D657461646174612E64656C6574656420262620217265636F72644D657461646174612E616767290D0A2020202020202020202020207B0D0A202020202020202020202020202020202F2F20776974682063757272656E';
wwv_flow_imp.g_varchar2_table(142) := '7420706C7567696E2066756E6374696F6E616C6974792C2077652063616E20636865636B20666F7220616C6C6F774564697420686572650D0A20202020202020202020202020202020696620286D6F64656C2E616C6C6F7745646974287265636F72644D';
wwv_flow_imp.g_varchar2_table(143) := '657461646174612E7265636F726429290D0A202020202020202020202020202020207B0D0A20202020202020202020202020202020202020206C657420726F77203D206D6F64656C5574696C2E6765745472616E736665724F626A656374286D6F64656C';
wwv_flow_imp.g_varchar2_table(144) := '2C207265636F72644D657461646174612C20646972656374697665293B0D0A20202020202020202020202020202020202020202F2F206F6E6C7920616464207768656E207468657265207761732061206368616E67650D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(145) := '202020202020202069662028287265636F72644D657461646174612E6F726967696E616C207C7C207265636F72644D657461646174612E696E7365727465642920262620284A534F4E2E737472696E6769667928726F772E6E6577526F772920213D3D20';
wwv_flow_imp.g_varchar2_table(146) := '4A534F4E2E737472696E6769667928726F772E6F6C64526F7729292920202020202020202020202020202020202020202020200D0A20202020202020202020202020202020202020207B2020202020202020202020202020202020200D0A202020202020';
wwv_flow_imp.g_varchar2_table(147) := '202020202020202020202020202020202020726571756573744F626A6563742E726F77732E7075736828726F77293B0D0A20202020202020202020202020202020202020207D0D0A202020202020202020202020202020207D0D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(148) := '2020207D0D0A20202020202020207D293B20200D0A202020202020202072657475726E20726571756573744F626A6563743B2020202020200D0A202020207D0D0A0D0A2020202066756E6374696F6E2070726F63657373526573706F6E73652872657370';
wwv_flow_imp.g_varchar2_table(149) := '6F6E73654F626A6563742C20696753746174696349642C206D6F64656C2C2073757070726573734368616E67654576656E7473290D0A202020207B0D0A20202020202020206C6574206772696456696577203D20617065782E726567696F6E2869675374';
wwv_flow_imp.g_varchar2_table(150) := '617469634964292E63616C6C2827676574566965777327292E677269643B0D0A20202020202020206C6574206163746976655265636F72644964203D2067726964566965772E76696577242E6772696428276765744163746976655265636F7264496427';
wwv_flow_imp.g_varchar2_table(151) := '293B200D0A2020202020202020726573706F6E73654F626A6563742E646174612E726F77732E666F72456163682866756E6374696F6E287472616E736665724F626A656374297B0D0A202020202020202020202020696620287472616E736665724F626A';
wwv_flow_imp.g_varchar2_table(152) := '6563742E6E6577526F77290D0A2020202020202020202020207B0D0A202020202020202020202020202020202F2F20676574207265636F7264206561726C79206173206C617465726F6E2061207072696D617279206B65792070617274206D6967687420';
wwv_flow_imp.g_varchar2_table(153) := '676574206368616E6765640D0A202020202020202020202020202020206C6574207265636F7264203D206D6F64656C2E6765745265636F7264287472616E736665724F626A6563742E7265636F72644964293B2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(154) := '202020202020202020202020202020202020200D0A202020202020202020202020202020206C6574207265636F72644D65746164617461203D206D6F64656C2E6765745265636F72644D65746164617461287472616E736665724F626A6563742E726563';
wwv_flow_imp.g_varchar2_table(155) := '6F72644964293B20202020200D0A20202020202020202020202020202020696620287265636F7264202626207265636F72644D65746164617461290D0A202020202020202020202020202020207B2020202020200D0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(156) := '2020202020206C6574206D6F64656C557064617465203D2066616C73653B202020202020202020202020202020202020202020202020202020200D0A2020202020202020202020202020202020202020666F722028636F6E7374205B6669656C644E616D';
wwv_flow_imp.g_varchar2_table(157) := '652C206E657756616C75655D206F66204F626A6563742E656E7472696573287472616E736665724F626A6563742E6E6577526F7729290D0A20202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(158) := '202020696620286E657756616C756520213D206E756C6C29202020202F2F206E657756616C75652063616E2774206265206E756C6C202D20627574206A75737420746F20626520737572650D0A2020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(159) := '207B0D0A202020202020202020202020202020202020202020202020202020206C6574206D6F64656C4669656C6473203D206D6F64656C2E6765744F7074696F6E28226669656C647322293B0D0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(160) := '202020202020696620286D6F64656C4669656C64732E6861734F776E50726F7065727479286669656C644E616D65292920202F2F20636865636B696E67206A75737420746F20626520737572650D0A202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(161) := '202020202020207B0D0A20202020202020202020202020202020202020202020202020202020202020206C6574206F6C6456616C7565203D207574696C2E6765745363616C617256616C7565287472616E736665724F626A6563742E6F6C64526F775B66';
wwv_flow_imp.g_varchar2_table(162) := '69656C644E616D655D293B0D0A2020202020202020202020202020202020202020202020202020202020202020696620286F6C6456616C756520213D3D207574696C2E6765745363616C617256616C7565286E657756616C756529290D0A202020202020';
wwv_flow_imp.g_varchar2_table(163) := '20202020202020202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202020202020202020206C65742063757272656E7456616C7565203D206D6F64656C5574696C2E6D6F64656C54';
wwv_flow_imp.g_varchar2_table(164) := '6F526F775363616C617256616C7565286D6F64656C2C207265636F72642C206669656C644E616D65293B0D0A2020202020202020202020202020202020202020202020202020202020202020202020206966202863757272656E7456616C7565203D3D3D';
wwv_flow_imp.g_varchar2_table(165) := '206F6C6456616C756529202020202F2F20636865636B2069662063757272656E742076616C7565206973207374696C6C20746865206F6C642076616C75650D0A202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(166) := '7B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020696620286D6F64656C2E616C6C6F7745646974287265636F726429290D0A202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(167) := '202020202020202020202020207B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202F2F20636865636B2072656164206F6E6C790D0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(168) := '2020202020202020202020202020202020202020202020206C657420636B203D206D6F64656C5574696C2E6765744669656C644D65746150726F706572747956616C7565287265636F72644D657461646174612C206669656C644E616D652C2027636B27';
wwv_flow_imp.g_varchar2_table(169) := '293B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202069662028636B203D3D206E756C6C207C7C20636B203D3D202727290D0A2020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(170) := '2020202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020206C657420697344697361626C6564203D206D6F64656C5574696C2E67';
wwv_flow_imp.g_varchar2_table(171) := '65744669656C644D65746150726F706572747956616C7565287265636F72644D657461646174612C206669656C644E616D652C202764697361626C656427293B0D0A20202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(172) := '20202020202020202020202020206966202821697344697361626C6564290D0A2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(173) := '20202020202020202020202020202020202020202020202020202020202020202020206C6574207265636F72644964203D206D6F64656C2E6765745265636F72644964287265636F7264293B0D0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(174) := '2020202020202020202020202020202020202020202020202020202020206C657420666F726D617474656456616C7565203D206D6F64656C5574696C2E726F77546F4D6F64656C56616C7565286D6F64656C2C206669656C644E616D652C206E65775661';
wwv_flow_imp.g_varchar2_table(175) := '6C7565293B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202F2F20696620616374697665207265636F72642C20646F20757064617465207669612074686520636F';
wwv_flow_imp.g_varchar2_table(176) := '6C756D6E206974656D20736F2077652063616E20737570707265737320746865206368616E6765206576656E742C200D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(177) := '202F2F2070726576656E74696E6720616E792044412F7365727665722D7369646520726571756573742067657474696E672074726967676572656420616761696E0D0A202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(178) := '20202020202020202020202020202020202020696620287265636F72644964203D3D3D206163746976655265636F72644964290D0A2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(179) := '20202020207B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020206C657420656C656D656E744964203D206D6F64656C4669656C64735B6669656C644E616D';
wwv_flow_imp.g_varchar2_table(180) := '655D2E656C656D656E7449643B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202069662028656C656D656E744964290D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(181) := '202020202020202020202020202020202020202020202020202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(182) := '20202020202069662028747970656F6620666F726D617474656456616C7565203D3D3D20276F626A6563742720262620666F726D617474656456616C75652E6861734F776E50726F70657274792827762729290D0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(183) := '2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(184) := '202020202020202020202020617065782E6974656D28656C656D656E744964292E73657456616C756528666F726D617474656456616C75652E762C20666F726D617474656456616C75652E642C2073757070726573734368616E67654576656E7473293B';
wwv_flow_imp.g_varchar2_table(185) := '0D0A2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(186) := '20202020202020202020202020202020202020202020202020656C73650D0A2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207B0D0A202020202020';
wwv_flow_imp.g_varchar2_table(187) := '20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020617065782E6974656D28656C656D656E744964292E73657456616C756528666F726D617474656456616C';
wwv_flow_imp.g_varchar2_table(188) := '75652C206E756C6C2C2073757070726573734368616E67654576656E7473293B0D0A2020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207D0D0A202020';
wwv_flow_imp.g_varchar2_table(189) := '20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202067726964566965772E76696577242E6772696428277365744163746976655265636F726456616C7565272C';
wwv_flow_imp.g_varchar2_table(190) := '206669656C644E616D65293B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207D0D0A202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(191) := '202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020656C73650D0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(192) := '20202020202020202020202020202020202020202020202020202020202020202020202020207B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020206D6F64';
wwv_flow_imp.g_varchar2_table(193) := '656C2E73657456616C7565287265636F72642C206669656C644E616D652C20666F726D617474656456616C7565293B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(194) := '20202020202F2F2072657365742076616C69646974790D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020206D6F64656C2E73657456616C6964697479282776';
wwv_flow_imp.g_varchar2_table(195) := '616C6964272C207265636F726449642C206669656C644E616D652C206E756C6C293B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020206D6F64656C557064';
wwv_flow_imp.g_varchar2_table(196) := '617465203D20747275653B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(197) := '202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(198) := '2020202020207D0D0A2020202020202020202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(199) := '202020202020202020202020202020696620287472616E736665724F626A6563742E6D6574612E6669656C64735B6669656C644E616D655D2E6861734F776E50726F706572747928276572726F722729290D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(200) := '2020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202020202020202020202F2F20676574207265636F72642069642066726F6D207265636F72642028616E64206E6F742066726F6D20747261';
wwv_flow_imp.g_varchar2_table(201) := '6E736665724F626A65637429206173206D65616E7768696C652061207072696D206B65792070617274206D696768742068617665206368616E6765640D0A2020202020202020202020202020202020202020202020202020202020202020202020206C65';
wwv_flow_imp.g_varchar2_table(202) := '74207265636F72644964203D206D6F64656C2E6765745265636F72644964287265636F7264293B202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200D0A20202020202020';
wwv_flow_imp.g_varchar2_table(203) := '2020202020202020202020202020202020202020202020202020202020696620287472616E736665724F626A6563742E6D6574612E6669656C64735B6669656C644E616D655D2E6572726F72290D0A202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(204) := '2020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202F2F6C6574206578697374696E674572726F72203D206D6F64656C5574696C2E6765744669656C644D65';
wwv_flow_imp.g_varchar2_table(205) := '746150726F706572747956616C7565287265636F72644D657461646174612C206669656C644E616D652C20276572726F7227293B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202F2F69662028';
wwv_flow_imp.g_varchar2_table(206) := '216578697374696E674572726F72290D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202F2F7B0D0A2020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(207) := '2020202020206D6F64656C2E73657456616C696469747928276572726F72272C207265636F726449642C206669656C644E616D652C207472616E736665724F626A6563742E6D6574612E6669656C64735B6669656C644E616D655D2E6D65737361676529';
wwv_flow_imp.g_varchar2_table(208) := '3B0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020202F2F7D0D0A2020202020202020202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(209) := '2020202020202020202020202020202020202020202020656C73650D0A2020202020202020202020202020202020202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(210) := '20202020202020202F2F20656D707479206572726F72206D6573736167652077617320736574207365727665722D736964650D0A202020202020202020202020202020202020202020202020202020202020202020202020202020206D6F64656C2E7365';
wwv_flow_imp.g_varchar2_table(211) := '7456616C6964697479282776616C6964272C207265636F726449642C206669656C644E616D652C206E756C6C293B0D0A2020202020202020202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(212) := '202020202020202020202020202020202020207D0D0A202020202020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(213) := '7D0D0A20202020202020202020202020202020202020202F2F696620287472616E736665724F626A6563742E6D6574612E6572726F7220262620217265636F72644D657461646174612E6572726F72290D0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(214) := '2020696620287472616E736665724F626A6563742E6D6574612E6572726F7229202020200D0A20202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020206C6574207265636F72644964203D20';
wwv_flow_imp.g_varchar2_table(215) := '6D6F64656C2E6765745265636F72644964287265636F7264293B202020202020202020202020202020202020202020202020202020202020202020202020202020200D0A2020202020202020202020202020202020202020202020206D6F64656C2E7365';
wwv_flow_imp.g_varchar2_table(216) := '7456616C696469747928276572726F72272C207265636F726449642C206E756C6C2C207472616E736665724F626A6563742E6D6574612E6D657373616765293B0D0A20202020202020202020202020202020202020207D20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(217) := '202020202020202020202020202020202020200D0A20202020202020202020202020202020202020202F2F2063757272656E74207265636F7264207374617465206265636F6D6573206D657461206F6C6420726F770D0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(218) := '202020202020206C6574206D6574614F6C64526F77203D206D6F64656C5574696C2E7265636F72644172726179546F4F626A656374286D6F64656C2C207265636F72644D657461646174612E7265636F7264293B0D0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(219) := '2020202020206D6F64656C5574696C2E7365744F6C64526F77287265636F72644D657461646174612C206D6574614F6C64526F77293B0D0A20202020202020202020202020202020202020206D6F64656C4D6F64756C652E656E73757265537562736372';
wwv_flow_imp.g_varchar2_table(220) := '69626564286D6F64656C293B0D0A2020202020202020202020202020202020202020696620286D6F64656C557064617465290D0A20202020202020202020202020202020202020207B0D0A20202020202020202020202020202020202020202020202061';
wwv_flow_imp.g_varchar2_table(221) := '7065782E6576656E742E74726967676572282723272B696753746174696349642C20276C69623478656E647265636F726465646974272C207B6D6F64656C3A206D6F64656C2C207265636F72643A207265636F72647D293B0D0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(222) := '202020202020202020207D0D0A202020202020202020202020202020207D0D0A2020202020202020202020207D0D0A20202020202020207D293B20202020202020200D0A202020207D0D0A0D0A202020202F2F20444120656E7472792066756E6374696F';
wwv_flow_imp.g_varchar2_table(223) := '6E0D0A202020206C65742065786563757465203D2066756E6374696F6E2829200D0A202020207B0D0A20202020202020206C657420646154686973203D20746869733B0D0A20202020202020206C657420616374696F6E203D206461546869732E616374';
wwv_flow_imp.g_varchar2_table(224) := '696F6E3B0D0A20202020202020206C65742069675374617469634964203D20616374696F6E2E6166666563746564526567696F6E49643B200D0A20202020202020206C6574206772696456696577203D20617065782E726567696F6E2869675374617469';
wwv_flow_imp.g_varchar2_table(225) := '634964292E63616C6C2827676574566965777327292E677269643B0D0A20202020202020202F2F2070726F6365737320616E792063656C6C206564697420696E746F20746865206D6F64656C20736F20746865206368616E676520616E6420616E792063';
wwv_flow_imp.g_varchar2_table(226) := '68616E6765732066726F6D206F6E4669656C644368616E67652068616E646C65722061726520696E636C7564656420696E207468652073657276657220726571756573740D0A20202020202020206C65742063757272656E7443656C6C24203D20677269';
wwv_flow_imp.g_varchar2_table(227) := '64566965772E76696577242E67726964282767657443757272656E7443656C6C27293B0D0A20202020202020206966202863757272656E7443656C6C242E6C656E677468203E2030290D0A20202020202020207B0D0A2020202020202020202020206C65';
wwv_flow_imp.g_varchar2_table(228) := '7420636F6C756D6E466F7243656C6C203D2067726964566965772E76696577242E677269642827676574436F6C756D6E466F7243656C6C272C2063757272656E7443656C6C24293B200D0A20202020202020202020202069662028636F6C756D6E466F72';
wwv_flow_imp.g_varchar2_table(229) := '43656C6C3F2E70726F7065727479290D0A2020202020202020202020207B0D0A202020202020202020202020202020202F2F20415045582077696C6C20636865636B2069662074686520636F6C756D6E206974656D2076616C756520697320756E657175';
wwv_flow_imp.g_varchar2_table(230) := '616C20746F207468652063757272656E74206D6F64656C2076616C75652028696E206D6F64656C2E73657456616C75652829290D0A2020202020202020202020202020202067726964566965772E76696577242E67726964282773657441637469766552';
wwv_flow_imp.g_varchar2_table(231) := '65636F726456616C7565272C20636F6C756D6E466F7243656C6C2E70726F7065727479293B0D0A2020202020202020202020207D0D0A20202020202020207D0D0A202020202020202069662028286461546869732E646174613F2E696753746174696349';
wwv_flow_imp.g_varchar2_table(232) := '64203D3D2069675374617469634964292026262028747970656F66206461546869732E646174613F2E72656769737465724173796E63203D3D3D202766756E6374696F6E2729290D0A20202020202020207B0D0A2020202020202020202020202F2F2074';
wwv_flow_imp.g_varchar2_table(233) := '68652070617274792077686F2077617320666972696E6720746865206576656E7420627920776869636820746865204441206973207472696767657265642077616E747320746F2062652063616C6C6564206261636B206F6E63652072656164790D0A20';
wwv_flow_imp.g_varchar2_table(234) := '20202020202020202020206461546869732E646174612E72656769737465724173796E63280D0A202020202020202020202020202020206E65772050726F6D69736528287265736F6C76652C2072656A65637429203D3E207B0D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(235) := '2020202020202020202020646F45786563757465286461546869732C207B0D0A202020202020202020202020202020202020202020202020737563636573733A207265736F6C76652C0D0A20202020202020202020202020202020202020202020202065';
wwv_flow_imp.g_varchar2_table(236) := '72726F723A2072656A6563740D0A20202020202020202020202020202020202020207D293B0D0A202020202020202020202020202020207D290D0A202020202020202020202020293B202020202020202020202020202020200D0A20202020202020207D';
wwv_flow_imp.g_varchar2_table(237) := '0D0A2020202020202020656C73650D0A20202020202020207B0D0A202020202020202020202020646F4578656375746528646154686973293B0D0A20202020202020207D0D0A202020207D0D0A0D0A202020206C657420646F45786563757465203D2066';
wwv_flow_imp.g_varchar2_table(238) := '756E6374696F6E286461546869732C2070726F6D69736543616C6C6261636B29200D0A202020207B0D0A20202020202020206C657420616374696F6E203D206461546869732E616374696F6E3B0D0A20202020202020206C657420646972656374697665';
wwv_flow_imp.g_varchar2_table(239) := '203D206461546869732E646174612E6469726563746976653B0D0A20202020202020206C657420726573756D6543616C6C6261636B203D206461546869732E726573756D6543616C6C6261636B3B202020202020202F2F20415045582063616C6C626163';
wwv_flow_imp.g_varchar2_table(240) := '6B2066756E6374696F6E2C20666163696C69746174696E6720275761697420466F7220526573756C7427206F7074696F6E0D0A20202020202020206C657420657865637574696F6E53636F7065203D20616374696F6E2E61747472696275746530313B0D';
wwv_flow_imp.g_varchar2_table(241) := '0A20202020202020206C6574206974656D73546F5375626D6974203D20616374696F6E2E61747472696275746530343F2E73706C697428272C27292E6D6170286974656D203D3E206974656D2E7472696D2829292E66696C746572286974656D203D3E20';
wwv_flow_imp.g_varchar2_table(242) := '6974656D20213D3D202727293B0D0A20202020202020206C65742073757070726573734368616E67654576656E7473203D2028616374696F6E2E6174747269627574653035203D3D3D20275927293B0D0A20202020202020206C65742069675374617469';
wwv_flow_imp.g_varchar2_table(243) := '634964203D20616374696F6E2E6166666563746564526567696F6E49643B0D0A2020202020202020696620282169675F726571756573744E6F2E6861734F776E50726F7065727479286967537461746963496429290D0A20202020202020207B0D0A2020';
wwv_flow_imp.g_varchar2_table(244) := '2020202020202020202069675F726571756573744E6F5B696753746174696349645D203D20303B0D0A20202020202020207D0D0A20202020202020206C6574206967526567696F6E203D20617065782E726567696F6E2869675374617469634964293B0D';
wwv_flow_imp.g_varchar2_table(245) := '0A20202020202020202F2F207465737420696620726567696F6E20697320616E2049470D0A2020202020202020696620286967526567696F6E3F2E7479706520213D2027496E746572616374697665477269642729207B0D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(246) := '207468726F77206E6577204572726F7228274C49423458202D2045786563757465205365727665722D5369646520494720526F77204C6F676963206572726F723A205C2727202B2069675374617469634964202B20275C27206973206E6F7420616E2049';
wwv_flow_imp.g_varchar2_table(247) := '6E746572616374697665204772696420526567696F6E27293B0D0A20202020202020207D0D0A20202020202020202F2F2073616665747920636865636B3A2067726964566965772073686F756C6420626520656E61626C65640D0A202020202020202069';
wwv_flow_imp.g_varchar2_table(248) := '662028216967526567696F6E2E77696467657428292E696E7465726163746976654772696428276F7074696F6E27292E636F6E6669673F2E76696577733F2E677269643F2E66656174757265733F2E677269645669657729207B0D0A2020202020202020';
wwv_flow_imp.g_varchar2_table(249) := '202020207468726F77206E6577204572726F7228274C49423458202D2045786563757465205365727665722D5369646520494720526F77204C6F676963206572726F723A205C2727202B2069675374617469634964202B20275C273A2074686520494720';
wwv_flow_imp.g_varchar2_table(250) := '67726964566965772066656174757265206973206E6F7420656E61626C656427293B0D0A20202020202020207D2020202020202020200D0A20202020202020206C6574206772696456696577203D20617065782E726567696F6E28696753746174696349';
wwv_flow_imp.g_varchar2_table(251) := '64292E63616C6C2827676574566965777327292E677269643B0D0A20202020202020206C6574206D6F64656C203D2067726964566965772E6D6F64656C3B0D0A20202020202020206C657420726571756573744F626A656374203D20636F6D706F736552';
wwv_flow_imp.g_varchar2_table(252) := '6571756573744F626A65637428696753746174696349642C206D6F64656C2C20657865637574696F6E53636F70652C20646972656374697665293B0D0A202020202020202069662028726571756573744F626A6563742E726F77732E6C656E677468203E';
wwv_flow_imp.g_varchar2_table(253) := '2030290D0A20202020202020207B0D0A2020202020202020202020206C657420637478203D207B0D0A20202020202020202020202020202020726571756573743A20726571756573744F626A6563740D0A2020202020202020202020207D202020202020';
wwv_flow_imp.g_varchar2_table(254) := '202020202020200D0A2020202020202020202020206669726553534C4576656E7428696753746174696349642C20276F6E52657175657374272C20637478293B0D0A2020202020202020202020202F2F20626C6F636B20746865204947207768696C6520';
wwv_flow_imp.g_varchar2_table(255) := '657865637574696E67207365727665722D73696465206C6F6769630D0A2020202020202020202020202F2F20617065782E7365727665722E706C7567696E2077696C6C207075742061207370696E6E6572202875706F6E206C696E676572292061732070';
wwv_flow_imp.g_varchar2_table(256) := '657220746865206C6F6164696E67496E64696361746F720D0A2020202020202020202020202F2F6C65742069674F7665726C617924203D207365744F7665726C617928696753746174696349642C2074727565293B2020202020202020202020200D0A20';
wwv_flow_imp.g_varchar2_table(257) := '20202020202020202020202F2F726571756573744F626A656374203D206374782E726571756573743B0D0A20202020202020202020202069662028657865637574696F6E53636F7065203D3D2045535F4143544956455F524F57290D0A20202020202020';
wwv_flow_imp.g_varchar2_table(258) := '20202020207B0D0A2020202020202020202020202020202067726964566965772E76696577242E6772696428276C6F636B41637469766527293B0D0A2020202020202020202020207D0D0A202020202020202020202020617065782E7365727665722E70';
wwv_flow_imp.g_varchar2_table(259) := '6C7567696E28616374696F6E2E616A61784964656E7469666965722C0D0A202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020706167654974656D733A206974656D73546F5375626D69742C0D0A20202020';
wwv_flow_imp.g_varchar2_table(260) := '20202020202020202020202020202020705F636C6F625F30313A204A534F4E2E737472696E6769667928726571756573744F626A656374290D0A202020202020202020202020202020207D2C0D0A202020202020202020202020202020207B0D0A202020';
wwv_flow_imp.g_varchar2_table(261) := '202020202020202020202020202020202064617461547970653A20276A736F6E272C0D0A20202020202020202020202020202020202020206C6F6164696E67496E64696361746F723A206461546869732E646174612E6C6F6164696E67496E6469636174';
wwv_flow_imp.g_varchar2_table(262) := '6F72203F3F20272327202B20696753746174696349642C0D0A20202020202020202020202020202020202020206C6F6164696E67496E64696361746F72506F736974696F6E3A202763656E7465726564272C0D0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(263) := '20202020737563636573733A2066756E6374696F6E28726573706F6E73654F626A656374290D0A20202020202020202020202020202020202020207B20202020202020202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(264) := '2020202020200D0A20202020202020202020202020202020202020202020202069662028726573706F6E73654F626A6563742E737461747573203D3D2027737563636573732729207B0D0A20202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(265) := '2020206C657420637478203D207B0D0A2020202020202020202020202020202020202020202020202020202020202020726571756573743A20726571756573744F626A6563742C0D0A202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(266) := '2020202020726573706F6E73653A20726573706F6E73654F626A6563742E646174610D0A202020202020202020202020202020202020202020202020202020207D202020202020202020202020200D0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(267) := '20202020202020206669726553534C4576656E7428696753746174696349642C20276F6E526573706F6E7365272C20637478293B2020200D0A202020202020202020202020202020202020202020202020202020202F2F20636865636B206966206C6174';
wwv_flow_imp.g_varchar2_table(268) := '65737420726571756573742C2069676E6F7265206F6C64657220726573706F6E736573200D0A2020202020202020202020202020202020202020202020202020202069662028726573706F6E73654F626A6563742E646174612E726571756573744E6F20';
wwv_flow_imp.g_varchar2_table(269) := '3D3D3D2069675F726571756573744E6F5B696753746174696349645D290D0A202020202020202020202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020202020202070726F636573';
wwv_flow_imp.g_varchar2_table(270) := '73526573706F6E736528726573706F6E73654F626A6563742C20696753746174696349642C206D6F64656C2C2073757070726573734368616E67654576656E7473293B202020202020202020202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(271) := '202020202020202020202020202020202020202020202020202020200D0A202020202020202020202020202020202020202020202020202020207D0D0A202020202020202020202020202020202020202020202020202020206966202870726F6D697365';
wwv_flow_imp.g_varchar2_table(272) := '43616C6C6261636B3F2E7375636365737329200D0A202020202020202020202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020202020202070726F6D69736543616C6C6261636B2E';
wwv_flow_imp.g_varchar2_table(273) := '7375636365737328293B0D0A202020202020202020202020202020202020202020202020202020207D202020202020202020202020202020202020202020202020202020200D0A2020202020202020202020202020202020202020202020202020202069';
wwv_flow_imp.g_varchar2_table(274) := '662028726573756D6543616C6C6261636B290D0A202020202020202020202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202020202020617065782E64612E726573756D65287265';
wwv_flow_imp.g_varchar2_table(275) := '73756D6543616C6C6261636B2C2066616C7365293B0D0A202020202020202020202020202020202020202020202020202020207D0D0A2020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(276) := '2020202020656C73652069662028726573706F6E73654F626A6563742E737461747573203D3D20276572726F722729207B0D0A202020202020202020202020202020202020202020202020202020202F2F20696E2063617365206F6620616E7920706C2F';
wwv_flow_imp.g_varchar2_table(277) := '73716C20657863657074696F6E2C2069742077696C6C206C616E6420757020686572650D0A202020202020202020202020202020202020202020202020202020206C657420637478203D207B0D0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(278) := '202020202020202020206572726F7244657461696C733A20726573706F6E73654F626A6563742E6572726F7244657461696C732C0D0A202020202020202020202020202020202020202020202020202020202020202073757070726573734572726F724D';
wwv_flow_imp.g_varchar2_table(279) := '6573736167653A2066616C73650D0A202020202020202020202020202020202020202020202020202020207D202020202020202020202020200D0A202020202020202020202020202020202020202020202020202020206669726553534C4576656E7428';
wwv_flow_imp.g_varchar2_table(280) := '696753746174696349642C20276F6E4572726F72272C20637478293B202020202020202020202020202020202020202020202020202020200D0A2020202020202020202020202020202020202020202020202020202069662028216374782E7375707072';
wwv_flow_imp.g_varchar2_table(281) := '6573734572726F724D65737361676520262620726573706F6E73654F626A6563742E6572726F7244657461696C732E6D6573736167655465787429207B0D0A2020202020202020202020202020202020202020202020202020202020202020617065782E';
wwv_flow_imp.g_varchar2_table(282) := '6D6573736167652E636C6561724572726F727328293B0D0A2020202020202020202020202020202020202020202020202020202020202020617065782E6D6573736167652E73686F774572726F7273285B0D0A2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(283) := '202020202020202020202020202020202020207B0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020747970653A20202020202020226572726F72222C0D0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(284) := '2020202020202020202020202020202020202020202020206C6F636174696F6E3A2020205B2270616765225D2C0D0A202020202020202020202020202020202020202020202020202020202020202020202020202020206D6573736167653A2020202072';
wwv_flow_imp.g_varchar2_table(285) := '6573706F6E73654F626A6563742E6572726F7244657461696C732E6D657373616765546578742C0D0A20202020202020202020202020202020202020202020202020202020202020202020202020202020756E736166653A202020202066616C73650D0A';
wwv_flow_imp.g_varchar2_table(286) := '2020202020202020202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020202020202020205D293B0D0A202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(287) := '202020207D0D0A202020202020202020202020202020202020202020202020202020206966202870726F6D69736543616C6C6261636B3F2E6572726F7229200D0A202020202020202020202020202020202020202020202020202020207B0D0A20202020';
wwv_flow_imp.g_varchar2_table(288) := '2020202020202020202020202020202020202020202020202020202070726F6D69736543616C6C6261636B2E6572726F7228293B0D0A202020202020202020202020202020202020202020202020202020207D2020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(289) := '202020202020202020202020200D0A2020202020202020202020202020202020202020202020202020202069662028726573756D6543616C6C6261636B290D0A202020202020202020202020202020202020202020202020202020207B0D0A2020202020';
wwv_flow_imp.g_varchar2_table(290) := '202020202020202020202020202020202020202020202020202020617065782E64612E726573756D6528726573756D6543616C6C6261636B2C2074727565293B0D0A202020202020202020202020202020202020202020202020202020207D2020202020';
wwv_flow_imp.g_varchar2_table(291) := '20202020202020202020202020202020202020202020200D0A2020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020207D2C0D0A20202020202020202020202020202020202020206572726F';
wwv_flow_imp.g_varchar2_table(292) := '723A2066756E6374696F6E28706A715848522C2070546578745374617475732C20704572726F725468726F776E290D0A20202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202F2F207570';
wwv_flow_imp.g_varchar2_table(293) := '6F6E20616E7920414A415820657863657074696F6E2C2069742077696C6C206C616E6420757020686572650D0A2020202020202020202020202020202020202020202020206966202870726F6D69736543616C6C6261636B3F2E6572726F7229200D0A20';
wwv_flow_imp.g_varchar2_table(294) := '20202020202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202070726F6D69736543616C6C6261636B2E6572726F7228293B0D0A2020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(295) := '202020207D2020202020202020202020202020202020202020202020200D0A202020202020202020202020202020202020202020202020617065782E64612E68616E646C65416A61784572726F727328706A715848522C2070546578745374617475732C';
wwv_flow_imp.g_varchar2_table(296) := '20704572726F725468726F776E2C20726573756D6543616C6C6261636B293B0D0A20202020202020202020202020202020202020207D2C0D0A2020202020202020202020202020202020202020636F6D706C6574653A2066756E6374696F6E28706A7158';
wwv_flow_imp.g_varchar2_table(297) := '48522C20705465787453746174757329200D0A20202020202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202F2F20636F6D706C6574653A20657865637574656420616674657220616E79207375';
wwv_flow_imp.g_varchar2_table(298) := '63636573732F6572726F722020202020202020202020202020202020202020202020200D0A20202020202020202020202020202020202020202020202069662028657865637574696F6E53636F7065203D3D2045535F4143544956455F524F57290D0A20';
wwv_flow_imp.g_varchar2_table(299) := '20202020202020202020202020202020202020202020207B0D0A202020202020202020202020202020202020202020202020202020206C6574206163746976655265636F72644964203D2067726964566965772E76696577242E67726964282767657441';
wwv_flow_imp.g_varchar2_table(300) := '63746976655265636F7264496427293B2020202020202020202020202020202020202020200D0A202020202020202020202020202020202020202020202020202020206C657420636F6E746578745265636F72644964203D206E756C6C3B202020202020';
wwv_flow_imp.g_varchar2_table(301) := '200D0A202020202020202020202020202020202020202020202020202020206C657420636F6E746578745265636F7264203D2067726964566965772E676574436F6E746578745265636F7264287574696C2E67657444656570416374697665456C656D65';
wwv_flow_imp.g_varchar2_table(302) := '6E7428617065782E6750616765436F6E74657874245B305D29293B0D0A2020202020202020202020202020202020202020202020202020202069662028636F6E746578745265636F72642E6C656E677468203E2030290D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(303) := '202020202020202020202020202020207B0D0A2020202020202020202020202020202020202020202020202020202020202020636F6E746578745265636F72644964203D206D6F64656C2E6765745265636F7264496428636F6E746578745265636F7264';
wwv_flow_imp.g_varchar2_table(304) := '5B305D293B0D0A202020202020202020202020202020202020202020202020202020207D0D0A20202020202020202020202020202020202020202020202020202020696620286163746976655265636F7264496420213D3D20636F6E746578745265636F';
wwv_flow_imp.g_varchar2_table(305) := '72644964290D0A202020202020202020202020202020202020202020202020202020207B20202020202020202020200D0A20202020202020202020202020202020202020202020202020202020202020202F2F2061637469766520726F77206973207374';
wwv_flow_imp.g_varchar2_table(306) := '696C6C206C6F636B656420627574206E6F7420666F63757373656420616E796D6F72650D0A20202020202020202020202020202020202020202020202020202020202020202F2F2041504558206973206E6F7420666972696E6720746865202761706578';
wwv_flow_imp.g_varchar2_table(307) := '656E647265636F72646564697427206576656E742075706F6E20756E6C6F636B696E670D0A20202020202020202020202020202020202020202020202020202020202020202F2F2028736565207769646765742E677269642E6A732C205F646561637469';
wwv_flow_imp.g_varchar2_table(308) := '76617465526F772066756E6374696F6E290D0A20202020202020202020202020202020202020202020202020202020202020202F2F20736F2077652077696C6C20646F20697420686572652061732074686520726F7720686173206C6F737420666F6375';
wwv_flow_imp.g_varchar2_table(309) := '730D0A20202020202020202020202020202020202020202020202020202020202020202F2F2075736572206D69676874206861766520676F6E6520746F20616E6F7468657220726F772C206F7220686974206120746F6F6C62617220627574746F6E2C20';
wwv_flow_imp.g_varchar2_table(310) := '6574632020202020202020202020202020200D0A20202020202020202020202020202020202020202020202020202020202020206C6574206163746976655265636F7264203D2067726964566965772E76696577242E6772696428276765744163746976';
wwv_flow_imp.g_varchar2_table(311) := '655265636F726427293B0D0A2020202020202020202020202020202020202020202020202020202020202020696620286163746976655265636F72644964202626206163746976655265636F7264290D0A20202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(312) := '202020202020202020202020207B0D0A20202020202020202020202020202020202020202020202020202020202020202020202067726964566965772E76696577242E677269642827696E7374616E636527292E5F74726967676572456E644564697469';
wwv_flow_imp.g_varchar2_table(313) := '6E67286163746976655265636F72642C206163746976655265636F72644964293B0D0A20202020202020202020202020202020202020202020202020202020202020207D0D0A202020202020202020202020202020202020202020202020202020207D0D';
wwv_flow_imp.g_varchar2_table(314) := '0A2020202020202020202020202020202020202020202020202020202067726964566965772E76696577242E677269642827756E6C6F636B41637469766527293B0D0A2020202020202020202020202020202020202020202020207D2020202020202020';
wwv_flow_imp.g_varchar2_table(315) := '202020202020202020202020202020200D0A2020202020202020202020202020202020202020202020202F2F69674F7665726C6179242E72656D6F766528293B0D0A20202020202020202020202020202020202020207D0D0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(316) := '20202020207D0D0A202020202020202020202020293B0D0A20202020202020207D0D0A2020202020202020656C73650D0A20202020202020207B0D0A2020202020202020202020206966202870726F6D69736543616C6C6261636B3F2E73756363657373';
wwv_flow_imp.g_varchar2_table(317) := '29200D0A2020202020202020202020207B0D0A2020202020202020202020202020202070726F6D69736543616C6C6261636B2E7375636365737328293B0D0A2020202020202020202020207D202020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(318) := '202020200D0A20202020202020202020202069662028726573756D6543616C6C6261636B290D0A2020202020202020202020207B0D0A20202020202020202020202020202020617065782E64612E726573756D6528726573756D6543616C6C6261636B2C';
wwv_flow_imp.g_varchar2_table(319) := '2066616C7365293B0D0A2020202020202020202020207D2020202020202020202020200D0A20202020202020207D0D0A202020207D202020200D0A0D0A202020202F2F2065787465726E616C20696E746572666163650D0A2020202077696E646F772E6C';
wwv_flow_imp.g_varchar2_table(320) := '69623478203D2077696E646F772E6C69623478207C7C207B7D3B0D0A202020206C696234782E6967203D206C696234782E6967207C7C207B7D3B0D0A202020206C696234782E69672E736572766572536964654C6F676963203D206C696234782E69672E';
wwv_flow_imp.g_varchar2_table(321) := '736572766572536964654C6F676963207C7C207B7D3B0D0A0D0A202020202F2F206F6E526571756573742C206F6E526573706F6E73652C206F6E4572726F72206576656E742068616E646C65727320737570706F727465640D0A202020206C696234782E';
wwv_flow_imp.g_varchar2_table(322) := '69672E736572766572536964654C6F6769632E726567697374657248616E646C657273203D2066756E6374696F6E28696753746174696349642C206576656E7448616E646C657273297B0D0A202020202020202069675F73736C5F6576656E7448616E64';
wwv_flow_imp.g_varchar2_table(323) := '6C6572735B696753746174696349645D203D206576656E7448616E646C6572733B0D0A202020207D3B0D0A202020206C696234782E69672E736572766572536964654C6F6769632E756E726567697374657248616E646C657273203D2066756E6374696F';
wwv_flow_imp.g_varchar2_table(324) := '6E2869675374617469634964297B0D0A202020202020202064656C6574652069675F73736C5F6576656E7448616E646C6572735B696753746174696349645D3B0D0A202020207D3B202020200D0A0D0A2020202072657475726E207B0D0A202020202020';
wwv_flow_imp.g_varchar2_table(325) := '20205F657865637574653A20657865637574650D0A202020207D202020200D0A7D2928617065782E6A5175657279293B';
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(48174578215271614)
,p_plugin_id=>wwv_flow_imp.id(48174220830181978)
,p_file_name=>'js/ig-serversidelogic.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '77696E646F772E6C696234783D77696E646F772E6C696234787C7C7B7D2C77696E646F772E6C696234782E6178743D77696E646F772E6C696234782E6178747C7C7B7D2C77696E646F772E6C696234782E6178742E69673D77696E646F772E6C69623478';
wwv_flow_imp.g_varchar2_table(2) := '2E6178742E69677C7C7B7D2C6C696234782E6178742E69672E736572766572536964654C6F6769633D66756E6374696F6E28297B636F6E737420653D2253434F50455F4143544956455F524F57223B6C657420743D7B7D2C723D7B7D2C693D66756E6374';
wwv_flow_imp.g_varchar2_table(3) := '696F6E28297B636F6E737420653D6E6577205765616B4D61703B72657475726E7B656E73757265537562736372696265643A66756E6374696F6E2874297B69662821652E686173287429297B6C657420723D742E737562736372696265287B6F6E436861';
wwv_flow_imp.g_varchar2_table(4) := '6E67653A66756E6374696F6E28652C72297B5B22726566726573685265636F726473222C22726576657274225D2E696E636C756465732865292626722E7265636F7264733F2E666F7245616368282866756E6374696F6E2865297B6C657420723D742E67';
wwv_flow_imp.g_varchar2_table(5) := '65745265636F726449642865292C693D742E6765745265636F72644D657461646174612872293B692E6C696234783F2E6F6C64526F77262664656C65746520692E6C696234782E6F6C64526F777D29297D2C6F6E44657374726F793A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(6) := '28297B652E64656C6574652874297D7D293B652E73657428742C72297D7D7D7D28292C6F3D7B6765745472616E736665724F626A6563743A66756E6374696F6E28652C742C72297B6C657420693D7B7D3B692E7265636F726449643D652E676574526563';
wwv_flow_imp.g_varchar2_table(7) := '6F7264496428742E7265636F7264292C72262628692E6469726563746976653D72292C692E6D6574613D7B7D2C692E6D6574612E6669656C64733D7B7D2C692E6E6577526F773D746869732E7265636F72644172726179546F4F626A65637428652C742E';
wwv_flow_imp.g_varchar2_table(8) := '7265636F7264292C742E6C696234783F2E6F6C64526F773F692E6F6C64526F773D742E6C696234782E6F6C64526F773A692E6F6C64526F773D746869732E7265636F72644172726179546F4F626A65637428652C742E6F726967696E616C3F3F742E7265';
wwv_flow_imp.g_varchar2_table(9) := '636F7264292C742E696E7365727465643F692E6D6574612E726F775374617475733D2243223A742E75706461746564262628692E6D6574612E726F775374617475733D225522293B6C6574206F3D652E6765744F7074696F6E28226669656C647322293B';
wwv_flow_imp.g_varchar2_table(10) := '666F7228636F6E73745B742C725D6F66204F626A6563742E656E7472696573286F2929746869732E69735265636F72644669656C6428652C7229262628692E6D6574612E6669656C64735B745D3D7B7D293B72657475726E20697D2C7265636F72644172';
wwv_flow_imp.g_varchar2_table(11) := '726179546F4F626A6563743A66756E6374696F6E28652C74297B6C657420723D6E756C6C2C693D652E6765744F7074696F6E28226669656C647322293B69662874262669297B723D7B7D3B666F7228636F6E73745B6F2C6C5D6F66204F626A6563742E65';
wwv_flow_imp.g_varchar2_table(12) := '6E747269657328692929746869732E69735265636F72644669656C6428652C6C29262628725B6F5D3D746869732E6D6F64656C546F526F7756616C756528652C742C6F29297D72657475726E20727D2C6D6F64656C546F526F775363616C617256616C75';
wwv_flow_imp.g_varchar2_table(13) := '653A66756E6374696F6E28652C742C72297B6C657420693D746869732E6D6F64656C546F526F7756616C756528652C742C72293B72657475726E206C2E6765745363616C617256616C75652869297D2C6D6F64656C546F526F7756616C75653A66756E63';
wwv_flow_imp.g_varchar2_table(14) := '74696F6E28652C742C72297B6C657420693D652E67657456616C756528742C72293B72657475726E206E756C6C213D692626226F626A656374223D3D747970656F662069262628693D73747275637475726564436C6F6E65286929292C746869732E6765';
wwv_flow_imp.g_varchar2_table(15) := '74556E666F726D617474656456616C756528692C652C72297D2C676574556E666F726D617474656456616C75653A66756E6374696F6E28652C742C72297B6C657420693D653B6966286E756C6C213D6526262222213D3D652626226F626A65637422213D';
wwv_flow_imp.g_varchar2_table(16) := '747970656F662065297B6C6574206F3D742E6765744F7074696F6E28226669656C647322295B725D2C6C3D6F2E64617461547970653B696628224E554D424552223D3D6C29693D537472696E6728617065782E6C6F63616C652E746F4E756D6265722865';
wwv_flow_imp.g_varchar2_table(17) := '2C6F2E666F726D61744D61736B29293B656C7365206966282244415445223D3D6C297B693D22223B7472797B693D617065782E646174652E706172736528652C6F2E666F726D61744D61736B297D63617463682865297B7D69262628693D617065782E64';
wwv_flow_imp.g_varchar2_table(18) := '6174652E746F49534F537472696E67286929297D7D72657475726E20697D2C726F77546F4D6F64656C56616C75653A66756E6374696F6E28652C742C72297B6C657420693D723B6966282222213D3D722626226F626A65637422213D747970656F662072';
wwv_flow_imp.g_varchar2_table(19) := '297B6C6574206F3D652E6765744F7074696F6E28226669656C647322295B745D2C6C3D6F2E64617461547970653B696628224E554D424552223D3D6C29693D617065782E6C6F63616C652E666F726D61744E756D626572284E756D6265722872292C6F2E';
wwv_flow_imp.g_varchar2_table(20) := '666F726D61744D61736B293B656C7365206966282244415445223D3D6C297472797B6C657420653D6E657720446174652872293B65262628693D617065782E646174652E666F726D617428652C6F2E666F726D61744D61736B29297D6361746368286529';
wwv_flow_imp.g_varchar2_table(21) := '7B7D7D72657475726E20697D2C69735265636F72644669656C643A66756E6374696F6E28652C74297B72657475726E20742E6861734F776E50726F70657274792822696E64657822292626742E70726F7065727479213D652E6765744F7074696F6E2822';
wwv_flow_imp.g_varchar2_table(22) := '6D6574614669656C6422297D2C6765744669656C644D657461646174613A66756E6374696F6E28652C742C72297B6C657420693D6E756C6C3B69662865297B6C6574206F3D652E6669656C64737C7C28723F652E6669656C64733D7B7D3A6E756C6C293B';
wwv_flow_imp.g_varchar2_table(23) := '6F262628693D6F5B745D7C7C28723F6F5B745D3D7B7D3A6E756C6C29297D72657475726E20697D2C6765744669656C644D65746150726F706572747956616C75653A66756E6374696F6E28652C742C72297B6C657420693D6E756C6C2C6F3D746869732E';
wwv_flow_imp.g_varchar2_table(24) := '6765744669656C644D6574616461746128652C742C2131293B72657475726E206F262628693D6F5B725D292C697D2C7365744F6C64526F773A66756E6374696F6E28652C74297B652E6C696234787C7C28652E6C696234783D7B7D292C652E6C69623478';
wwv_flow_imp.g_varchar2_table(25) := '2E6F6C64526F773D747D7D2C6C3D7B6765745363616C617256616C75653A66756E6374696F6E2865297B72657475726E206E756C6C213D3D652626226F626A656374223D3D747970656F6620652626652E6861734F776E50726F70657274792822762229';
wwv_flow_imp.g_varchar2_table(26) := '262628653D652E762C41727261792E69734172726179286529262628653D4A534F4E2E737472696E6769667928652929292C657D2C67657444656570416374697665456C656D656E743A66756E6374696F6E28653D646F63756D656E74297B6C65742074';
wwv_flow_imp.g_varchar2_table(27) := '3D652E616374697665456C656D656E743B666F72283B74262622494652414D45223D3D3D742E7461674E616D653B297472797B743D28742E636F6E74656E74446F63756D656E747C7C742E636F6E74656E7457696E646F772E646F63756D656E74292E61';
wwv_flow_imp.g_varchar2_table(28) := '6374697665456C656D656E747D63617463682865297B627265616B7D72657475726E20747D7D3B66756E6374696F6E206128652C722C69297B617065782E64656275672E747261636528226C696234782D6576656E74202849472D53534C293A20222C72';
wwv_flow_imp.g_varchar2_table(29) := '2C69292C66756E6374696F6E28652C72297B6C657420693D6E756C6C3B696628742E6861734F776E50726F7065727479286529297B6C6574206F3D745B655D3B2266756E6374696F6E223D3D747970656F66206F5B725D262628693D6F5B725D297D7265';
wwv_flow_imp.g_varchar2_table(30) := '7475726E20697D28652C72293F2E2869297D6C6574206E3D66756E6374696F6E28742C6E297B6C657420643D742E616374696F6E2C733D742E646174612E6469726563746976652C633D742E726573756D6543616C6C6261636B2C753D642E6174747269';
wwv_flow_imp.g_varchar2_table(31) := '6275746530312C673D642E61747472696275746530343F2E73706C697428222C22292E6D61702828653D3E652E7472696D282929292E66696C7465722828653D3E2222213D3D6529292C663D2259223D3D3D642E61747472696275746530352C773D642E';
wwv_flow_imp.g_varchar2_table(32) := '6166666563746564526567696F6E49643B722E6861734F776E50726F70657274792877297C7C28725B775D3D30293B6C657420703D617065782E726567696F6E2877293B69662822496E7465726163746976654772696422213D703F2E74797065297468';
wwv_flow_imp.g_varchar2_table(33) := '726F77206E6577204572726F7228224C49423458202D2045786563757465205365727665722D5369646520494720526F77204C6F676963206572726F723A2027222B772B2227206973206E6F7420616E20496E7465726163746976652047726964205265';
wwv_flow_imp.g_varchar2_table(34) := '67696F6E22293B69662821702E77696467657428292E696E7465726163746976654772696428226F7074696F6E22292E636F6E6669673F2E76696577733F2E677269643F2E66656174757265733F2E6772696456696577297468726F77206E6577204572';
wwv_flow_imp.g_varchar2_table(35) := '726F7228224C49423458202D2045786563757465205365727665722D5369646520494720526F77204C6F676963206572726F723A2027222B772B22273A207468652049472067726964566965772066656174757265206973206E6F7420656E61626C6564';
wwv_flow_imp.g_varchar2_table(36) := '22293B6C657420783D617065782E726567696F6E2877292E63616C6C2822676574566965777322292E677269642C6D3D782E6D6F64656C2C623D66756E6374696F6E28742C692C6C2C61297B6C6574206E3D617065782E726567696F6E2874292E63616C';
wwv_flow_imp.g_varchar2_table(37) := '6C2822676574566965777322292E677269642C643D7B7D3B725B745D3D725B745D2B312C642E726571756573744E6F3D725B745D2C642E726F77733D5B5D3B6C657420733D5B5D3B6966286C3D3D65297B6C657420653D6E2E76696577242E6772696428';
wwv_flow_imp.g_varchar2_table(38) := '226765744163746976655265636F7264496422293B69662865297B6C657420743D692E6765745265636F72644D657461646174612865293B742626732E707573682874297D7D656C73652253434F50455F435245415445445F4D4F444946494544223D3D';
wwv_flow_imp.g_varchar2_table(39) := '6C262628733D692E6765744368616E6765732829293B72657475726E20732E666F7245616368282866756E6374696F6E2865297B69662821652E64656C65746564262621652E6167672626692E616C6C6F774564697428652E7265636F726429297B6C65';
wwv_flow_imp.g_varchar2_table(40) := '7420743D6F2E6765745472616E736665724F626A65637428692C652C61293B28652E6F726967696E616C7C7C652E696E7365727465642926264A534F4E2E737472696E6769667928742E6E6577526F7729213D3D4A534F4E2E737472696E676966792874';
wwv_flow_imp.g_varchar2_table(41) := '2E6F6C64526F77292626642E726F77732E707573682874297D7D29292C647D28772C6D2C752C73293B696628622E726F77732E6C656E6774683E30297B6128772C226F6E52657175657374222C7B726571756573743A627D292C753D3D652626782E7669';
wwv_flow_imp.g_varchar2_table(42) := '6577242E6772696428226C6F636B41637469766522292C617065782E7365727665722E706C7567696E28642E616A61784964656E7469666965722C7B706167654974656D733A672C705F636C6F625F30313A4A534F4E2E737472696E676966792862297D';
wwv_flow_imp.g_varchar2_table(43) := '2C7B64617461547970653A226A736F6E222C6C6F6164696E67496E64696361746F723A742E646174612E6C6F6164696E67496E64696361746F723F3F2223222B772C6C6F6164696E67496E64696361746F72506F736974696F6E3A2263656E7465726564';
wwv_flow_imp.g_varchar2_table(44) := '222C737563636573733A66756E6374696F6E2865297B6966282273756363657373223D3D652E737461747573297B6C657420743D7B726571756573743A622C726573706F6E73653A652E646174617D3B6128772C226F6E526573706F6E7365222C74292C';
wwv_flow_imp.g_varchar2_table(45) := '652E646174612E726571756573744E6F3D3D3D725B775D262666756E6374696F6E28652C742C722C61297B6C6574206E3D617065782E726567696F6E2874292E63616C6C2822676574566965777322292E677269642C643D6E2E76696577242E67726964';
wwv_flow_imp.g_varchar2_table(46) := '28226765744163746976655265636F7264496422293B652E646174612E726F77732E666F7245616368282866756E6374696F6E2865297B696628652E6E6577526F77297B6C657420733D722E6765745265636F726428652E7265636F72644964292C633D';
wwv_flow_imp.g_varchar2_table(47) := '722E6765745265636F72644D6574616461746128652E7265636F72644964293B69662873262663297B6C657420753D21313B666F7228636F6E73745B742C695D6F66204F626A6563742E656E747269657328652E6E6577526F7729296966286E756C6C21';
wwv_flow_imp.g_varchar2_table(48) := '3D69297B6C657420673D722E6765744F7074696F6E28226669656C647322293B696628672E6861734F776E50726F7065727479287429297B6C657420663D6C2E6765745363616C617256616C756528652E6F6C64526F775B745D293B69662866213D3D6C';
wwv_flow_imp.g_varchar2_table(49) := '2E6765745363616C617256616C756528692926266F2E6D6F64656C546F526F775363616C617256616C756528722C732C74293D3D3D662626722E616C6C6F7745646974287329297B6C657420653D6F2E6765744669656C644D65746150726F7065727479';
wwv_flow_imp.g_varchar2_table(50) := '56616C756528632C742C22636B22293B696628286E756C6C3D3D657C7C22223D3D65292626216F2E6765744669656C644D65746150726F706572747956616C756528632C742C2264697361626C65642229297B6C657420653D722E6765745265636F7264';
wwv_flow_imp.g_varchar2_table(51) := '49642873292C6C3D6F2E726F77546F4D6F64656C56616C756528722C742C69293B696628653D3D3D64297B6C657420653D675B745D2E656C656D656E7449643B65262628226F626A656374223D3D747970656F66206C26266C2E6861734F776E50726F70';
wwv_flow_imp.g_varchar2_table(52) := '6572747928227622293F617065782E6974656D2865292E73657456616C7565286C2E762C6C2E642C61293A617065782E6974656D2865292E73657456616C7565286C2C6E756C6C2C61292C6E2E76696577242E6772696428227365744163746976655265';
wwv_flow_imp.g_varchar2_table(53) := '636F726456616C7565222C7429297D656C736520722E73657456616C756528732C742C6C292C722E73657456616C6964697479282276616C6964222C652C742C6E756C6C292C753D21307D7D696628652E6D6574612E6669656C64735B745D2E6861734F';
wwv_flow_imp.g_varchar2_table(54) := '776E50726F706572747928226572726F722229297B6C657420693D722E6765745265636F726449642873293B652E6D6574612E6669656C64735B745D2E6572726F723F722E73657456616C696469747928226572726F72222C692C742C652E6D6574612E';
wwv_flow_imp.g_varchar2_table(55) := '6669656C64735B745D2E6D657373616765293A722E73657456616C6964697479282276616C6964222C692C742C6E756C6C297D7D7D696628652E6D6574612E6572726F72297B6C657420743D722E6765745265636F726449642873293B722E7365745661';
wwv_flow_imp.g_varchar2_table(56) := '6C696469747928226572726F72222C742C6E756C6C2C652E6D6574612E6D657373616765297D6C657420673D6F2E7265636F72644172726179546F4F626A65637428722C632E7265636F7264293B6F2E7365744F6C64526F7728632C67292C692E656E73';
wwv_flow_imp.g_varchar2_table(57) := '757265537562736372696265642872292C752626617065782E6576656E742E74726967676572282223222B742C226C69623478656E647265636F726465646974222C7B6D6F64656C3A722C7265636F72643A737D297D7D7D29297D28652C772C6D2C6629';
wwv_flow_imp.g_varchar2_table(58) := '2C6E3F2E7375636365737326266E2E7375636365737328292C632626617065782E64612E726573756D6528632C2131297D656C736520696628226572726F72223D3D652E737461747573297B6C657420743D7B6572726F7244657461696C733A652E6572';
wwv_flow_imp.g_varchar2_table(59) := '726F7244657461696C732C73757070726573734572726F724D6573736167653A21317D3B6128772C226F6E4572726F72222C74292C21742E73757070726573734572726F724D6573736167652626652E6572726F7244657461696C732E6D657373616765';
wwv_flow_imp.g_varchar2_table(60) := '54657874262628617065782E6D6573736167652E636C6561724572726F727328292C617065782E6D6573736167652E73686F774572726F7273285B7B747970653A226572726F72222C6C6F636174696F6E3A5B2270616765225D2C6D6573736167653A65';
wwv_flow_imp.g_varchar2_table(61) := '2E6572726F7244657461696C732E6D657373616765546578742C756E736166653A21317D5D29292C6E3F2E6572726F7226266E2E6572726F7228292C632626617065782E64612E726573756D6528632C2130297D7D2C6572726F723A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(62) := '28652C742C72297B6E3F2E6572726F7226266E2E6572726F7228292C617065782E64612E68616E646C65416A61784572726F727328652C742C722C63297D2C636F6D706C6574653A66756E6374696F6E28742C72297B696628753D3D65297B6C65742065';
wwv_flow_imp.g_varchar2_table(63) := '3D782E76696577242E6772696428226765744163746976655265636F7264496422292C743D6E756C6C2C723D782E676574436F6E746578745265636F7264286C2E67657444656570416374697665456C656D656E7428617065782E6750616765436F6E74';
wwv_flow_imp.g_varchar2_table(64) := '657874245B305D29293B696628722E6C656E6774683E30262628743D6D2E6765745265636F7264496428725B305D29292C65213D3D74297B6C657420743D782E76696577242E6772696428226765744163746976655265636F726422293B652626742626';
wwv_flow_imp.g_varchar2_table(65) := '782E76696577242E677269642822696E7374616E636522292E5F74726967676572456E6445646974696E6728742C65297D782E76696577242E677269642822756E6C6F636B41637469766522297D7D7D297D656C7365206E3F2E7375636365737326266E';
wwv_flow_imp.g_varchar2_table(66) := '2E7375636365737328292C632626617065782E64612E726573756D6528632C2131297D3B72657475726E2077696E646F772E6C696234783D77696E646F772E6C696234787C7C7B7D2C6C696234782E69673D6C696234782E69677C7C7B7D2C6C69623478';
wwv_flow_imp.g_varchar2_table(67) := '2E69672E736572766572536964654C6F6769633D6C696234782E69672E736572766572536964654C6F6769637C7C7B7D2C6C696234782E69672E736572766572536964654C6F6769632E726567697374657248616E646C6572733D66756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(68) := '652C72297B745B655D3D727D2C6C696234782E69672E736572766572536964654C6F6769632E756E726567697374657248616E646C6572733D66756E6374696F6E2865297B64656C65746520745B655D7D2C7B5F657865637574653A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(69) := '28297B6C657420653D746869732C743D652E616374696F6E2E6166666563746564526567696F6E49642C723D617065782E726567696F6E2874292E63616C6C2822676574566965777322292E677269642C693D722E76696577242E677269642822676574';
wwv_flow_imp.g_varchar2_table(70) := '43757272656E7443656C6C22293B696628692E6C656E6774683E30297B6C657420653D722E76696577242E677269642822676574436F6C756D6E466F7243656C6C222C69293B653F2E70726F70657274792626722E76696577242E677269642822736574';
wwv_flow_imp.g_varchar2_table(71) := '4163746976655265636F726456616C7565222C652E70726F7065727479297D652E646174613F2E696753746174696349643D3D7426262266756E6374696F6E223D3D747970656F6620652E646174613F2E72656769737465724173796E633F652E646174';
wwv_flow_imp.g_varchar2_table(72) := '612E72656769737465724173796E63286E65772050726F6D697365282828742C72293D3E7B6E28652C7B737563636573733A742C6572726F723A727D297D2929293A6E2865297D7D7D28617065782E6A5175657279293B';
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(55396462314769753)
,p_plugin_id=>wwv_flow_imp.id(48174220830181978)
,p_file_name=>'js/ig-serversidelogic.min.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
