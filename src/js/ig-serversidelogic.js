window.lib4x = window.lib4x || {};
window.lib4x.axt = window.lib4x.axt || {};
window.lib4x.axt.ig = window.lib4x.axt.ig || {};

/*
 * lib4x.axt.ig.serverSideLogic
 * Enables to apply IG row logic server side for one or multiple rows, including manipulating column values and setting validation messages.
 * For a row, both an 'oldRow' and a 'newRow' object are included in the request, enabling to check the old values as well. The old values reflect
 * the values for the previous server request, or are the original values if no request was send yet.
 * Also a meta object is send for row level and field level meta data. Currently, the meta(fields) are send as empty, where server-side, error details
 * can be added (error/message).
 * Upon receiving the response, any new values/validation messages are processed into the model. 
 */
lib4x.axt.ig.serverSideLogic = (function($) {

    // execution scope
    const ES_ACTIVE_ROW = 'SCOPE_ACTIVE_ROW';
    const ES_CREATED_MODIFIED = 'SCOPE_CREATED_MODIFIED';

    // event handlers by ig static id
    let ig_ssl_eventHandlers = {};
    // request seqNo by ig static id
    let ig_requestNo = {};


    let modelModule = (function() {

        const subscriptions = new WeakMap();

        /*
         * subscribe to model notifications as upon save (refreshRecords) and undo (revert),
         * any oldRow on the record metdata to be removed. 
         * oldRow being a custom setting specifically for this plugin to 
         * keep track of the previously send row to the server, as those values serve as
         * old values on the next server request.
         * A save or undo means a reset, and the old values for the next request will
         * stem from the original record as maintained by APEX in the model metadata.
         */
        function ensureSubscribed(model) {
            if (!subscriptions.has(model)) {
                let sub = model.subscribe({
                    onChange: function(changeType, change) {
                        if (['refreshRecords', 'revert'].includes(changeType))
                        {
                            change.records?.forEach(function(record){
                                let recordId = model.getRecordId(record);
                                let recMetadata = model.getRecordMetadata(recordId);
                                if (recMetadata.lib4x?.oldRow)
                                {
                                    delete recMetadata.lib4x.oldRow;
                                }
                            });
                        }
                    },
                    onDestroy: function() {
                        subscriptions.delete(model);
                    }
                });
                subscriptions.set(model, sub);
            }
        }

        return {
            ensureSubscribed: ensureSubscribed
        }
    })();

    let modelUtil = {   
        // compose the row object including oldRow/newRow and meta(fields)
        getTransferObject: function(model, recMetadata, directive)
        {
            let transferObject = {};
            transferObject.recordId = model.getRecordId(recMetadata.record);
            if (directive)
            {
                transferObject.directive = directive;
            }
            transferObject
            transferObject.meta = {};
            transferObject.meta.fields = {};
            //if (recMetadata.original)
            //{
                transferObject.newRow = this.recordArrayToObject(model, recMetadata.record);
                //transferObject.meta.original = this.recordArrayToObject(model, recMetadata.original);
                if (recMetadata.lib4x?.oldRow)
                {
                    transferObject.oldRow = recMetadata.lib4x.oldRow;
                }
                else
                {
                    transferObject.oldRow = this.recordArrayToObject(model, recMetadata.original ?? recMetadata.record);
                }
            //}
            /*let props = ['error', 'warning', 'message'];
            for (const prop of props) {
                if (prop in recMetadata) {
                    transferObject.meta[prop] = recMetadata[prop];
                }
            }*/
            if (recMetadata.inserted)
            {
                transferObject.meta.rowStatus = 'C';
            }
            else if (recMetadata.updated)
            {
                transferObject.meta.rowStatus = 'U';
            }
            let modelFields = model.getOption("fields");
            for (const [fieldName, modelField] of Object.entries(modelFields))
            {
                if (this.isRecordField(model, modelField))
                {
                    //if (recMetadata.fields?.hasOwnProperty(fieldName))
                    //{
                    //    transferObject.meta.fields[fieldName] = structuredClone(recMetadata.fields[fieldName]);
                    //}
                    //else
                    //{
                        transferObject.meta.fields[fieldName] = {};         // currently, we are sending just empty, and server-side, error details can be set
                    //}
                }
            }
            return transferObject;
        },
        // derive a row object from a model record (which is an array)
        // for numbers, unformatted values are taken; for dates the ISO date
        recordArrayToObject: function(model, record)
        {
            let recordObject = null;
            let modelFields = model.getOption("fields");
            if (record && modelFields)
            {
                recordObject = {};
                for (const [fieldName, modelField] of Object.entries(modelFields))
                {  
                    if (this.isRecordField(model, modelField))
                    {
                        recordObject[fieldName] = this.modelToRowValue(model, record, fieldName);
                    }
                }
            }
            return recordObject;
        },    
        modelToRowScalarValue: function(model, record, property)
        {
            let value = this.modelToRowValue(model, record, property);
            return util.getScalarValue(value);
        },
        // modelToRowValue
        // get value as string; if number field, the value will be unformatted, eg "4578.45". 
        // dates are in ISO format as per apex.date.toISOString(), eg: "2026-03-26T13:00:00"
        modelToRowValue: function(model, record, property)
        {
            let value = model.getValue(record, property);
            if (value != null && typeof value === 'object')
            {
                // make a clone as the value might get updated from the current cell
                value = structuredClone(value);
            }
            return this.getUnformattedValue(value, model, property);
        },  
        getUnformattedValue: function(value, model, property)
        {
            let unformattedValue = value;
            if (value != null && value !== '' && typeof value !== 'object')
            {            
                let modelFields = model.getOption('fields');
                let modelField = modelFields[property];
                let dataType = modelField.dataType;
                if (dataType == 'NUMBER')
                {
                    unformattedValue = String(apex.locale.toNumber(value, modelField.formatMask));
                }
                else if (dataType == 'DATE')
                {
                    unformattedValue = '';
                    try
                    {
                        unformattedValue = apex.date.parse(value, modelField.formatMask);
                    }
                    catch(error) {};
                    if (unformattedValue)
                    {
                        // DATE type in Oracle has no timezone info, so we send parsed date as-is, same as IG is sending upon save
                        unformattedValue = apex.date.toISOString(unformattedValue);   // ISO string without timezone. Eg: 2026-03-26T13:00:00
                    }
                } 
            }
            return unformattedValue;           
        },
        // rowToModelValue
        // numbers will get formatted
        // dates will transform from ISO format to date as per any format mask
        rowToModelValue: function(model, property, value)
        {
            let modelValue = value;
            if (value !== '' && typeof value !== 'object')
            {
                let modelFields = model.getOption('fields');
                let modelField = modelFields[property];
                let dataType = modelField.dataType;
                if (dataType == 'NUMBER')
                {
                    modelValue = apex.locale.formatNumber(Number(value), modelField.formatMask);
                }
                else if (dataType == 'DATE')
                {
                    try
                    {
                        let dateValue = new Date(value);
                        if (dateValue)
                        {
                            modelValue = apex.date.format(dateValue, modelField.formatMask);
                        }    
                    }
                    catch(error){};                
                }                
            }
            return modelValue;
        },
        isRecordField: function(model, modelField)
        {
            return (modelField.hasOwnProperty('index') && modelField.property != model.getOption('metaField')); 
        },        
        getFieldMetadata: function(recMetadata, fieldName, createIfNotExists) {
            let result = null;
            if (recMetadata) {
                let fields = recMetadata.fields || (createIfNotExists ? recMetadata.fields = {} : null);
                if (fields) {
                    result = fields[fieldName] || (createIfNotExists ? fields[fieldName] = {} : null);
                }
            }           
            return result;
        },
        getFieldMetaPropertyValue: function(recMetadata, fieldName, metaProperty) {
            let result = null;
            let fieldMetadata = this.getFieldMetadata(recMetadata, fieldName, false);
            if (fieldMetadata) {
                result = fieldMetadata[metaProperty];
            }
            return result;
        },
        // APEX is only keeping track of the actual record and the original
        // for the plugin, we also keep track of oldRow, which reflects the row as send in the previous server request        
        setOldRow: function(recordMetadata, oldRow)
        {
            if (!recordMetadata.lib4x)
            {
                recordMetadata.lib4x= {};
            }
            recordMetadata.lib4x.oldRow = oldRow;            
        }                    
    }

    let util = {   
        getScalarValue: function(value)
        {
            if (value !== null && typeof value === "object" && value.hasOwnProperty( "v" ))
            {
                value = value.v;
                if (Array.isArray(value))
                {
                    value = JSON.stringify(value);
                }
            }
            return value;
        },
        getDeepActiveElement: function(doc = document) {
            let active = doc.activeElement;
            while (active && active.tagName === 'IFRAME') {
                try {
                    let innerDoc = active.contentDocument || active.contentWindow.document;
                    active = innerDoc.activeElement;
                } catch (e) {
                    // Cross-origin iframe → cannot access inside
                    break;
                }
            }
            return active;
        }        
    };

    function getEventHandler(igStaticId, handlerName)
    {
        let result = null;
        if (ig_ssl_eventHandlers.hasOwnProperty(igStaticId))
        {
            let eventHandlers = ig_ssl_eventHandlers[igStaticId];
            if (typeof eventHandlers[handlerName] === 'function')     
            {
                result = eventHandlers[handlerName];
            }   
        }
        return result;    
    }

    function fireSSLEvent(igStaticId, name, ctx)
    {
        apex.debug.trace('lib4x-event (IG-SSL): ', name, ctx);
        getEventHandler(igStaticId, name)?.(ctx);
    }    

    function setOverlay(igStaticId, transparent)
    {
        let css = {position: 'absolute'};
        if (transparent) {
            css['background-color'] = 'unset';
        }
        return $('<div class="apex_wait_overlay"></div>').css(css).prependTo($('#' + igStaticId));
    }    

    function composeRequestObject(igStaticId, model, executionScope, directive)
    {
        let gridView = apex.region(igStaticId).call('getViews').grid;
        let requestObject = {};
        ig_requestNo[igStaticId] = ig_requestNo[igStaticId] + 1;        
        requestObject.requestNo = ig_requestNo[igStaticId];
        requestObject.rows = [];
        let modelChanges = [];
        if (executionScope == ES_ACTIVE_ROW)
        {
            let activeRecordId = gridView.view$.grid('getActiveRecordId'); 
            if (activeRecordId)
            {
                let recordMetadata = model.getRecordMetadata(activeRecordId);
                if (recordMetadata)
                {
                    modelChanges.push(recordMetadata);
                }
            }
        }
        else if (executionScope == ES_CREATED_MODIFIED)
        {
            modelChanges = model.getChanges();
        }
        modelChanges.forEach(function(recordMetadata) {
            if (!recordMetadata.deleted && !recordMetadata.agg)
            {
                // with current plugin functionality, we can check for allowEdit here
                if (model.allowEdit(recordMetadata.record))
                {
                    let row = modelUtil.getTransferObject(model, recordMetadata, directive);
                    // only add when there was a change
                    if ((recordMetadata.original || recordMetadata.inserted) && (JSON.stringify(row.newRow) !== JSON.stringify(row.oldRow)))                       
                    {                  
                        requestObject.rows.push(row);
                    }
                }
            }
        });  
        return requestObject;      
    }

    function processResponse(responseObject, igStaticId, model, suppressChangeEvents)
    {
        let gridView = apex.region(igStaticId).call('getViews').grid;
        let activeRecordId = gridView.view$.grid('getActiveRecordId'); 
        responseObject.data.rows.forEach(function(transferObject){
            if (transferObject.newRow)
            {
                // get record early as lateron a primary key part might get changed
                let record = model.getRecord(transferObject.recordId);                                    
                let recordMetadata = model.getRecordMetadata(transferObject.recordId);     
                if (record && recordMetadata)
                {      
                    let modelUpdate = false;                            
                    for (const [fieldName, newValue] of Object.entries(transferObject.newRow))
                    {
                        if (newValue != null)    // newValue can't be null - but just to be sure
                        {
                            let modelFields = model.getOption("fields");
                            if (modelFields.hasOwnProperty(fieldName))  // checking just to be sure
                            {
                                let oldValue = util.getScalarValue(transferObject.oldRow[fieldName]);
                                if (oldValue !== util.getScalarValue(newValue))
                                {
                                    let currentValue = modelUtil.modelToRowScalarValue(model, record, fieldName);
                                    if (currentValue === oldValue)    // check if current value is still the old value
                                    {
                                        if (model.allowEdit(record))
                                        {
                                            // check read only
                                            let ck = modelUtil.getFieldMetaPropertyValue(recordMetadata, fieldName, 'ck');
                                            if (ck == null || ck == '')
                                            {
                                                let isDisabled = modelUtil.getFieldMetaPropertyValue(recordMetadata, fieldName, 'disabled');
                                                if (!isDisabled)
                                                {
                                                    let recordId = model.getRecordId(record);
                                                    let formattedValue = modelUtil.rowToModelValue(model, fieldName, newValue);
                                                    // if active record, do update via the column item so we can suppress the change event, 
                                                    // preventing any DA/server-side request getting triggered again
                                                    if (recordId === activeRecordId)
                                                    {
                                                        let elementId = modelFields[fieldName].elementId;
                                                        if (elementId)
                                                        {
                                                            if (typeof formattedValue === 'object' && formattedValue.hasOwnProperty('v'))
                                                            {
                                                                apex.item(elementId).setValue(formattedValue.v, formattedValue.d, suppressChangeEvents);
                                                            }
                                                            else
                                                            {
                                                                apex.item(elementId).setValue(formattedValue, null, suppressChangeEvents);
                                                            }
                                                            gridView.view$.grid('setActiveRecordValue', fieldName);
                                                        }
                                                    }
                                                    else
                                                    {
                                                        model.setValue(record, fieldName, formattedValue);
                                                        // reset validity
                                                        model.setValidity('valid', recordId, fieldName, null);
                                                        modelUpdate = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if (transferObject.meta.fields[fieldName].hasOwnProperty('error'))
                                {
                                    // get record id from record (and not from transferObject) as meanwhile a prim key part might have changed
                                    let recordId = model.getRecordId(record);                                                    
                                    if (transferObject.meta.fields[fieldName].error)
                                    {
                                        //let existingError = modelUtil.getFieldMetaPropertyValue(recordMetadata, fieldName, 'error');
                                        //if (!existingError)
                                        //{
                                            model.setValidity('error', recordId, fieldName, transferObject.meta.fields[fieldName].message);
                                        //}
                                    }
                                    else
                                    {
                                        // empty error message was set server-side
                                        model.setValidity('valid', recordId, fieldName, null);
                                    }
                                }
                            }
                        }
                    }
                    //if (transferObject.meta.error && !recordMetadata.error)
                    if (transferObject.meta.error)    
                    {
                        let recordId = model.getRecordId(record);                                        
                        model.setValidity('error', recordId, null, transferObject.meta.message);
                    }                                
                    // current record state becomes meta old row
                    let metaOldRow = modelUtil.recordArrayToObject(model, recordMetadata.record);
                    modelUtil.setOldRow(recordMetadata, metaOldRow);
                    modelModule.ensureSubscribed(model);
                    if (modelUpdate)
                    {
                        apex.event.trigger('#'+igStaticId, 'lib4xendrecordedit', {model: model, record: record});
                    }
                }
            }
        });        
    }

    // DA entry function
    let execute = function() 
    {
        let daThis = this;
        let action = daThis.action;
        let igStaticId = action.affectedRegionId; 
        let gridView = apex.region(igStaticId).call('getViews').grid;
        // process any cell edit into the model so the change and any changes from onFieldChange handler are included in the server request
        let currentCell$ = gridView.view$.grid('getCurrentCell');
        if (currentCell$.length > 0)
        {
            let columnForCell = gridView.view$.grid('getColumnForCell', currentCell$); 
            if (columnForCell?.property)
            {
                // APEX will check if the column item value is unequal to the current model value (in model.setValue())
                gridView.view$.grid('setActiveRecordValue', columnForCell.property);
            }
        }
        if ((daThis.data?.igStaticId == igStaticId) && (typeof daThis.data?.registerAsync === 'function'))
        {
            // the party who was firing the event by which the DA is triggered wants to be called back once ready
            daThis.data.registerAsync(
                new Promise((resolve, reject) => {
                    doExecute(daThis, {
                        success: resolve,
                        error: reject
                    });
                })
            );                
        }
        else
        {
            doExecute(daThis);
        }
    }

    let doExecute = function(daThis, promiseCallback) 
    {
        let action = daThis.action;
        let directive = daThis.data.directive;
        let resumeCallback = daThis.resumeCallback;       // APEX callback function, facilitating 'Wait For Result' option
        let executionScope = action.attribute01;
        let itemsToSubmit = action.attribute04?.split(',').map(item => item.trim()).filter(item => item !== '');
        let suppressChangeEvents = (action.attribute05 === 'Y');
        let igStaticId = action.affectedRegionId;
        if (!ig_requestNo.hasOwnProperty(igStaticId))
        {
            ig_requestNo[igStaticId] = 0;
        }
        let igRegion = apex.region(igStaticId);
        // test if region is an IG
        if (igRegion?.type != 'InteractiveGrid') {
            throw new Error('LIB4X - Execute Server-Side IG Row Logic error: \'' + igStaticId + '\' is not an Interactive Grid Region');
        }
        // safety check: gridView should be enabled
        if (!igRegion.widget().interactiveGrid('option').config?.views?.grid?.features?.gridView) {
            throw new Error('LIB4X - Execute Server-Side IG Row Logic error: \'' + igStaticId + '\': the IG gridView feature is not enabled');
        }         
        let gridView = apex.region(igStaticId).call('getViews').grid;
        let model = gridView.model;
        let requestObject = composeRequestObject(igStaticId, model, executionScope, directive);
        if (requestObject.rows.length > 0)
        {
            let ctx = {
                request: requestObject
            }             
            fireSSLEvent(igStaticId, 'onRequest', ctx);
            // block the IG while executing server-side logic
            // apex.server.plugin will put a spinner (upon linger) as per the loadingIndicator
            //let igOverlay$ = setOverlay(igStaticId, true);            
            //requestObject = ctx.request;
            if (executionScope == ES_ACTIVE_ROW)
            {
                gridView.view$.grid('lockActive');
            }
            apex.server.plugin(action.ajaxIdentifier,
                {
                    pageItems: itemsToSubmit,
                    p_clob_01: JSON.stringify(requestObject)
                },
                {
                    dataType: 'json',
                    loadingIndicator: daThis.data.loadingIndicator ?? '#' + igStaticId,
                    loadingIndicatorPosition: 'centered',
                    success: function(responseObject)
                    {                                              
                        if (responseObject.status == 'success') {
                            let ctx = {
                                request: requestObject,
                                response: responseObject.data
                            }             
                            fireSSLEvent(igStaticId, 'onResponse', ctx);   
                            // check if latest request, ignore older responses 
                            if (responseObject.data.requestNo === ig_requestNo[igStaticId])
                            {
                                processResponse(responseObject, igStaticId, model, suppressChangeEvents);                                                             
                            }
                            if (promiseCallback?.success) 
                            {
                                promiseCallback.success();
                            }                            
                            if (resumeCallback)
                            {
                                apex.da.resume(resumeCallback, false);
                            }
                        }
                        else if (responseObject.status == 'error') {
                            // in case of any pl/sql exception, it will land up here
                            let ctx = {
                                errorDetails: responseObject.errorDetails,
                                suppressErrorMessage: false
                            }             
                            fireSSLEvent(igStaticId, 'onError', ctx);                            
                            if (!ctx.suppressErrorMessage && responseObject.errorDetails.messageText) {
                                apex.message.clearErrors();
                                apex.message.showErrors([
                                    {
                                        type:       "error",
                                        location:   ["page"],
                                        message:    responseObject.errorDetails.messageText,
                                        unsafe:     false
                                    }
                                ]);
                            }
                            if (promiseCallback?.error) 
                            {
                                promiseCallback.error();
                            }                              
                            if (resumeCallback)
                            {
                                apex.da.resume(resumeCallback, true);
                            }                            
                        }
                    },
                    error: function(pjqXHR, pTextStatus, pErrorThrown)
                    {
                        // upon any AJAX exception, it will land up here
                        if (promiseCallback?.error) 
                        {
                            promiseCallback.error();
                        }                        
                        apex.da.handleAjaxErrors(pjqXHR, pTextStatus, pErrorThrown, resumeCallback);
                    },
                    complete: function(pjqXHR, pTextStatus) 
                    {
                        // complete: executed after any success/error                        
                        if (executionScope == ES_ACTIVE_ROW)
                        {
                            let activeRecordId = gridView.view$.grid('getActiveRecordId');                     
                            let contextRecordId = null;       
                            let contextRecord = gridView.getContextRecord(util.getDeepActiveElement(apex.gPageContext$[0]));
                            if (contextRecord.length > 0)
                            {
                                contextRecordId = model.getRecordId(contextRecord[0]);
                            }
                            if (activeRecordId !== contextRecordId)
                            {           
                                // active row is still locked but not focussed anymore
                                // APEX is not firing the 'apexendrecordedit' event upon unlocking
                                // (see widget.grid.js, _deactivateRow function)
                                // so we will do it here as the row has lost focus
                                // user might have gone to another row, or hit a toolbar button, etc               
                                let activeRecord = gridView.view$.grid('getActiveRecord');
                                if (activeRecordId && activeRecord)
                                {
                                    gridView.view$.grid('instance')._triggerEndEditing(activeRecord, activeRecordId);
                                }
                            }
                            gridView.view$.grid('unlockActive');
                        }                        
                        //igOverlay$.remove();
                    }
                }
            );
        }
        else
        {
            if (promiseCallback?.success) 
            {
                promiseCallback.success();
            }                            
            if (resumeCallback)
            {
                apex.da.resume(resumeCallback, false);
            }            
        }
    }    

    // external interface
    window.lib4x = window.lib4x || {};
    lib4x.ig = lib4x.ig || {};
    lib4x.ig.serverSideLogic = lib4x.ig.serverSideLogic || {};

    // onRequest, onResponse, onError event handlers supported
    lib4x.ig.serverSideLogic.registerHandlers = function(igStaticId, eventHandlers){
        ig_ssl_eventHandlers[igStaticId] = eventHandlers;
    };
    lib4x.ig.serverSideLogic.unregisterHandlers = function(igStaticId){
        delete ig_ssl_eventHandlers[igStaticId];
    };    

    return {
        _execute: execute
    }    
})(apex.jQuery);
