// This file contains your Data Connector logic
section Archimatika.IO.Jira;

[DataSource.Kind="Archimatika.IO.Jira", Publish="Archimatika.IO.Jira.Publish"]
shared Archimatika.IO.Jira.Contents = () =>
	let
		GetJiraData = 
		let
			iRateLimit = 50,
			sJiraServiceAddress = "https://archimatika.atlassian.net/rest/api",
			sAPIVersion = "3",
			sAdrsDlm = "/",
			sURL = Text.Combine({sJiraServiceAddress, sAPIVersion},sAdrsDlm),
			sRESTaction = "search?fields",
			sRESTfields = "issuetype,customfield_10070,timespent,project,resolution,workratio,lastViewed,lastViewed,watches,created,timeestimate,issuelinks,assignee,updated,status,timeoriginalestimate,description,aggregatetimeestimate,summary,subtasks,reporter,duedate,progress,  worklog",
			sSrchDlm = "=",
			sURLRelPath = Text.Combine({sRESTaction, sRESTfields},sSrchDlm),
			iStartCounter = 0,
			iMAxResults = 1,
			dtJiraIssueCounter = Json.Document(Web.Contents(sURL,
				[
					RelativePath = "/" & sURLRelPath,
					Query =
					[
						startAt     = Number.ToText(iStartCounter),
						maxResults  = Number.ToText(iMAxResults)
					],
					Timeout = #duration(0, 0, 5, 0)
				])),
			iIssuesCount = dtJiraIssueCounter[total],
			lIssueLimits = List.Generate(() => 0, each _ > -1 and _ < iIssuesCount, each _ + iRateLimit),
			#"List_ConvtoTable" = Table.FromList(lIssueLimits, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
			#"Table_RenamedColumns" = Table.RenameColumns(#"List_ConvtoTable",{{"Column1", "startAt"}}),

			PaginationFunc = Table.AddColumn(#"Table_RenamedColumns", "PaginationFunc", each CustomLoopFunc(Text.From([startAt]))),
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
				#"List_ConvtoTable_1" = Table.FromList(dtIssuesDB, Splitter.SplitByNothing(), null, null, ExtraValues.Error) 
			in 
				#"List_ConvtoTable_1"
		in
			PaginationFunc,

		ExpandJiraData = 
		let
			#"GetJiraData_Expanded" = Table.ExpandTableColumn(GetJiraData, "PaginationFunc", {"Column1"}, {"Issue"}),
			#"Columns_Removed" = Table.RemoveColumns(#"GetJiraData_Expanded",{"startAt"}),
			#"Issues_Expanded" = Table.ExpandRecordColumn(#"Columns_Removed", "Issue", {"id", "key", "fields"}, {"Issue.id", "Issue.key", "Issue"}),
			#"Issues_Expanded_2" = Table.ExpandRecordColumn(#"Issues_Expanded", "Issue", {"summary", "lastViewed", "issuetype", "watches", "customfield_10070", "subtasks", "created", "timespent", "timeoriginalestimate", "project", "description", "reporter", "resolution", "aggregatetimeestimate", "timeestimate", "duedate","customfield_10015","customfield_10033", "workratio", "progress", "issuelinks", "assignee", "worklog", "updated", "status"}, {"Issue.summary", "Issue.lastViewed", "Issue.issuetype", "Issue.watches", "Issue.customfield_10070", "Issue.subtasks", "Issue.created", "Issue.timespent", "Issue.timeoriginalestimate", "Issue.project", "Issue.description", "Issue.reporter", "Issue.resolution", "Issue.aggregatetimeestimate", "Issue.timeestimate", "Issue.duedate", "Issue.startDate", "Issue.endDate", "Issue.workratio", "Issue.progress", "Issue.issuelinks", "Issue.assignee", "Issue.worklog", "Issue.updated", "Issue.status"}),
			#"ExpandData" = Table.ExpandRecordColumn(#"Issues_Expanded_2", "Issue.issuetype", {"name"}, {"Issue.issuetype.name"}) 
		in
			#"ExpandData"    
	in
		ExpandJiraData;

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
