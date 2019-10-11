// This file contains your Data Connector logic
section Archimatika.IO.Jira;

// iRateLimit = 50;
// sJiraServiceAddress = "https://archimatika.atlassian.net/rest/api";
// sAPIVersion = "3";
// sAdrsDlm = "/";
// iRowNumber = 1000;
// sRESTactionIssues = "search?fields";
// sRESTactionUsers = "users/search";
// sRESTfields = "issuetype,customfield_10070,timespent,project,resolution,workratio,lastViewed,lastViewed,watches,created,timeestimate,issuelinks,assignee,updated,status,timeoriginalestimate,description,aggregatetimeestimate,summary,subtasks,reporter,duedate,progress,  worklog";
// sSrchDlm = "=";
// iStartCounter = 0;
// iMAxResults = 1;

// JSONContent         = File.Contents("C:\Users\d.radomtsev\source\repos\Archimatika.IO.Jira\config.json");
// JSONData            = Json.Document(JSONContent);
// Table_Imported      = Record.ToTable(JSONData);
// Table_Transposed    = Table.Transpose(Table_Imported);
// Headers_Promoted    = Table.PromoteHeaders(Table_Transposed, [PromoteAllScalars=true]);
// iRateLimit          = Headers_Promoted{0}[iRateLimit];
// sJiraServiceAddress = Headers_Promoted{0}[sJiraServiceAddress];
// sAPIVersion         = Headers_Promoted{0}[sAPIVersion];
// sAdrsDlm            = Headers_Promoted{0}[sAdrsDlm];
// iRowNumber          = Headers_Promoted{0}[iRowNumber];
// sRESTactionIssues   = Headers_Promoted{0}[sRESTactionIssues];
// sRESTactionUsers    = Headers_Promoted{0}[sRESTactionUsers];
// sRESTfields         = Headers_Promoted{0}[sRESTfields];
// sSrchDlm            = Headers_Promoted{0}[sSrchDlm];
// iStartCounter       = Headers_Promoted{0}[iStartCounter];
// iMAxResults         = Headers_Promoted{0}[iMAxResults];

Init = () => 
    let
            JSONContent         = File.Contents("C:\Users\d.radomtsev\source\repos\Archimatika.IO.Jira\config.json"),
            JSONData            = Json.Document(JSONContent),
            Table_Imported      = Record.ToTable(JSONData),
            Table_Transposed    = Table.Transpose(Table_Imported),
            Headers_Promoted    = Table.PromoteHeaders(Table_Transposed, [PromoteAllScalars=true]),

            iRateLimit          = Headers_Promoted{0}[iRateLimit],
            sJiraServiceAddress = Headers_Promoted{0}[sJiraServiceAddress],
            sAPIVersion         = Headers_Promoted{0}[sAPIVersion],
            sAdrsDlm            = Headers_Promoted{0}[sAdrsDlm],
            iRowNumber          = Headers_Promoted{0}[iRowNumber],
            sRESTactionIssues   = Headers_Promoted{0}[sRESTactionIssues],
            sRESTactionUsers    = Headers_Promoted{0}[sRESTactionUsers],
            sRESTfields         = Headers_Promoted{0}[sRESTfields],
            sSrchDlm            = Headers_Promoted{0}[sSrchDlm],
            iStartCounter       = Headers_Promoted{0}[iStartCounter],
            iMAxResults         = Headers_Promoted{0}[iMAxResults]
    in
       {iRateLimit, sJiraServiceAddress, sAPIVersion, sAdrsDlm, iRowNumber, sRESTactionIssues, sRESTactionUsers, sRESTfields, sSrchDlm, iStartCounter, iMAxResults};

// let
//     JSONContent         = File.Contents("C:\Users\d.radomtsev\source\repos\Archimatika.IO.Jira\config.json"),
//     JSONData            = Json.Document(JSONContent),
//     Table_Imported      = Record.ToTable(JSONData),
//     Table_Transposed    = Table.Transpose(Table_Imported),
//     Headers_Promoted    = Table.PromoteHeaders(Table_Transposed, [PromoteAllScalars=true]),
// 
//     iRateLimit          = Headers_Promoted{0}[iRateLimit],
//     sJiraServiceAddress = Headers_Promoted{0}[sJiraServiceAddress],
//     sAPIVersion         = Headers_Promoted{0}[sAPIVersion],
//     sAdrsDlm            = Headers_Promoted{0}[sAdrsDlm],
//     iRowNumber          = Headers_Promoted{0}[iRowNumber],
//     sRESTactionIssues   = Headers_Promoted{0}[sRESTactionIssues],
//     sRESTactionUsers    = Headers_Promoted{0}[sRESTactionUsers],
//     sRESTfields         = Headers_Promoted{0}[sRESTfields],
//     sSrchDlm            = Headers_Promoted{0}[sSrchDlm],
//     iStartCounter       = Headers_Promoted{0}[iStartCounter],
//     iMAxResults         = Headers_Promoted{0}[iMAxResults]
// in
//     {iRateLimit, sJiraServiceAddress, sAPIVersion, sAdrsDlm, iRowNumber, sRESTactionIssues, sRESTactionUsers, sRESTfields, sSrchDlm, iStartCounter, iMAxResults};

[DataSource.Kind="Archimatika.IO.Jira", Publish="Archimatika.IO.Jira.Publish"]
shared CreateNavTable = () as table => 
    let
		objects = #table(
            {"Name",            "Key",              "Data",                                 "ItemKind", "ItemName", "IsLeaf"},{
            {"Issues+Worklog",	"Issues+Worklog",   Archimatika.IO.Jira.IssuesWorklog(),    "Table",    "Table",	true},            
            {"Users",			"Users",			Archimatika.IO.Jira.Users(),	        "Table",    "Table",	true}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable;

//[DataSource.Kind="Archimatika.IO.Jira", Publish="Archimatika.IO.Jira.Publish"]
shared Archimatika.IO.Jira.IssuesWorklog = (iRateLimit, sJiraServiceAddress, sAPIVersion, sAdrsDlm, iRowNumber, sRESTactionIssues, sRESTactionUsers, sRESTfields, sSrchDlm, iStartCounter, iMAxResults ) =>
	let
		GetJiraData = 
		let
			sURL = Text.Combine({sJiraServiceAddress, sAPIVersion},sAdrsDlm),
			sURLRelPath = Text.Combine({sRESTactionIssues, sRESTfields},sSrchDlm),
			dtJiraIssueCounter = Json.Document(Web.Contents(sURL,
				[
					RelativePath = "/" & sURLRelPath,
					Query =
					[
						startAt     = Number.ToText(iStartCounter),
						maxResults  = Number.ToText(iMAxResults)
					],
					Timeout = #duration(0, 0, 1, 0)
				])),
			iIssuesCount = dtJiraIssueCounter[total],
			lIssueLimits = List.Generate(() => 0, each _ > -1 and _ < iIssuesCount, each _ + iRateLimit),
			List_ConvtoTable = Table.FromList(lIssueLimits, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
			Table_RenamedColumns = Table.RenameColumns(List_ConvtoTable,{{"Column1", "startAt"}}),

			PaginationFunc = Table.AddColumn(Table_RenamedColumns, "PaginationFunc", each CustomLoopFunc(Text.From([startAt]))),
			CustomLoopFunc = (startAt as text) => 
			let
				dtJiraDataSource = Json.Document(Web.Contents(sURL,
				[
					RelativePath = "/" & sURLRelPath,
					Query =
					[
						startAt     = startAt,
						maxResults  = Text.From(iRateLimit)
					],
					Timeout = #duration(0, 0, 15, 0)
				])),
				dtIssuesDB = dtJiraDataSource[issues],
				List_ConvtoTable_1 = Table.FromList(dtIssuesDB, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
			in 
				List_ConvtoTable_1
		in
			PaginationFunc,

		ExpandJiraData = 
		let
			GetJiraData_Expanded = Table.ExpandTableColumn(GetJiraData, "PaginationFunc", {"Column1"}, {"Issue"}),
			Columns_Removed = Table.RemoveColumns(GetJiraData_Expanded,{"startAt"}),
			Issues_Expanded = Table.ExpandRecordColumn(Columns_Removed, "Issue", {"id", "key", "fields"}, {"Issue.id", "Issue.key", "Issue"}),
			Issues_Expanded_2 = Table.ExpandRecordColumn(Issues_Expanded, "Issue", {"summary", "lastViewed", "issuetype", "watches", "customfield_10070", "subtasks", "created", "timespent", "timeoriginalestimate", "project", "description", "reporter", "resolution", "aggregatetimeestimate", "timeestimate", "duedate","customfield_10015","customfield_10033", "workratio", "progress", "issuelinks", "assignee", "worklog", "updated", "status"}, {"Issue.summary", "Issue.lastViewed", "Issue.issuetype", "Issue.watches", "Issue.customfield_10070", "Issue.subtasks", "Issue.created", "Issue.timespent", "Issue.timeoriginalestimate", "Issue.project", "Issue.description", "Issue.reporter", "Issue.resolution", "Issue.aggregatetimeestimate", "Issue.timeestimate", "Issue.duedate", "Issue.startDate", "Issue.endDate", "Issue.workratio", "Issue.progress", "Issue.issuelinks", "Issue.assignee", "Issue.worklog", "Issue.updated", "Issue.status"}),
			ExpandData = Table.ExpandRecordColumn(Issues_Expanded_2, "Issue.issuetype", {"name"}, {"Issue.issuetype.name"}) 
		in
			ExpandData   
	in
		ExpandJiraData;

shared Archimatika.IO.Jira.Users = (iRateLimit, sJiraServiceAddress, sAPIVersion, sAdrsDlm, iRowNumber, sRESTactionIssues, sRESTactionUsers, sRESTfields, sSrchDlm, iStartCounter, iMAxResults) =>
	let
		GetJiraData = let
		    Limits = List.Generate(()=>0, each _ > -1 and _ < iRowNumber, each _ + iRateLimit),
		    List_ConvtoTable = Table.FromList(Limits, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
		    Table_RenamedColumns = Table.RenameColumns(List_ConvtoTable,{{"Column1", "startAt"}}),

            sURL = Text.Combine({sJiraServiceAddress, sAPIVersion},sAdrsDlm),
		    sURLRelPath = sRESTactionUsers,
		    PaginationFunc = Table.AddColumn(Table_RenamedColumns, "PaginationFunc", each CustomLoopFunc(Text.From([startAt]))),
		    CustomLoopFunc = (startAt as text) => 
		    let
            
			    dtJiraDataSource = Json.Document(Web.Contents(sURL,
				    [
					    RelativePath = "/" & sURLRelPath,
					    Query =
					    [
						    startAt     = startAt,
						    maxResults  = Text.From(iRateLimit)
					    ],
					    Timeout = #duration(0, 0, 5, 0)
				    ])),
			    List_ConvtoTable_1 = Table.FromList(dtJiraDataSource, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
			    Column1_Expanded = Table.ExpandRecordColumn(List_ConvtoTable_1, "Column1", {"self", "accountId", "accountType", "displayName"}, {"Column1.self", "Column1.accountId", "Column1.accountType", "Column1.displayName"})
		    in
			    Column1_Expanded
	    in
		    PaginationFunc,

        ExpanJiraData = let
            Errors_Fixed = Table.RemoveRowsWithErrors(GetJiraData),
            Columns_Removed = Table.RemoveColumns(Errors_Fixed,{"startAt"}),
		    Errors_fix = Table.RemoveRowsWithErrors(Columns_Removed, {"PaginationFunc"}),
		    PaginationFunc_Extended = Table.ExpandTableColumn(Errors_fix, "PaginationFunc", {"Column1.self", "Column1.accountId", "Column1.accountType", "Column1.displayName"}, {"PaginationFunc.Column1.self", "PaginationFunc.Column1.accountId", "PaginationFunc.Column1.accountType", "PaginationFunc.Column1.displayName"}),
            Columns_Added = Table.AddIndexColumn(PaginationFunc_Extended, "index", 0, 1),
            Coluumns_Reordered = Table.ReorderColumns(Columns_Added, {"index","PaginationFunc.Column1.self", "PaginationFunc.Column1.accountId", "PaginationFunc.Column1.accountType", "PaginationFunc.Column1.displayName"})
        in
            Coluumns_Reordered
	in
		ExpanJiraData;

Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;

// Data Source Kind description
Archimatika.IO.Jira = [
    Authentication = [
        // Key = [],
        UsernamePassword = [
			UsernameLabel = "User name in format user@domain",
			PasswordLabel = "User password in format of API Token"
		]
        // Windows = [],
        //Implicit = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
Archimatika.IO.Jira.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = Archimatika.IO.Jira.Icons,
    SourceTypeImage = Archimatika.IO.Jira.Icons
];

Archimatika.IO.Jira.Icons = [
    Icon16 = { Extension.Contents("Archimatika.IO.Jira16.png"), Extension.Contents("Archimatika.IO.Jira20.png"), Extension.Contents("Archimatika.IO.Jira24.png"), Extension.Contents("Archimatika.IO.Jira32.png") },
    Icon32 = { Extension.Contents("Archimatika.IO.Jira32.png"), Extension.Contents("Archimatika.IO.Jira40.png"), Extension.Contents("Archimatika.IO.Jira48.png"), Extension.Contents("Archimatika.IO.Jira64.png") }
];
