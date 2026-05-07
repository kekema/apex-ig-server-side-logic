# apex-ig-server-side-logic
Enables to apply IG row logic server side for one or multiple rows, including manipulating column values and setting validation messages.

<p>
<img width="60%" height="60%" alt="image" src="https://github.com/user-attachments/assets/2bb00cd4-93f2-4f74-97d8-75445b40fc45" />
</p>
<p>PL/SQL anonymous block: use bind syntax to read or write row values as per the column name, eg: <code>:NAME</code>, <code>:JOB</code>, <code>:ORDER_STATUS</code></p>

Special bind variables (read):<br/>
<code>:LIB4X$ROW_STATUS</code> : 'C' for newly created row; 'U' for updated row.<br/>
<code>:LIB4X$DIRECTIVE</code> : when triggering the DA on multiple places, a directive can be feeded via the event data and can be used to steer the pl/sql logic.<br/>
<code>:LIB4X$<Column Name>_OLD</code> : value reflecting the value when the code block was executed previously, or the original value.<br/>
<code>:LIB4X$<Column Name>_CHANGED</code> : 'Y' or 'N' : whether the value has changed as compared to the OLD value.<br/>

Special bind variables (write):<br/>
<code>:LIB4X$ERROR_MSG</code> : to set any validation message on the row level. Use empty value to unset any existing message.<br/>
<code>:LIB4X$<Column Name>_DISPLAY</code> : for LOV type of columns, enabling you to set the display value.<br/>
<code>:LIB4X$<Column Name>_ERROR_MSG</code> : to set any validation message on the column level. Use empty value to unset any existing message.<br/>

<p>Values are always as strings. Numbers will be unformatted, eg: "4578.45". Dates are in ISO format as per apex.date.toISOString(), eg: "2026-03-26T13:00:00". This is both read/write.</p>

<p>
Execution Scope:
</p>
<img width="60%" height="60%" alt="image" src="https://github.com/user-attachments/assets/4fbca4c1-75b8-438a-8e77-c18d83a37832" />

<h3>Plugin versions</h3>
Version 1.0.0 - build under APEX 24.2<br>
