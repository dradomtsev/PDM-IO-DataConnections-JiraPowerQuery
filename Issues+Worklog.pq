let
    iRateLimit = 50,
    sJiraServiceAddress = "https://archimatika.atlassian.net/rest/api",
    sAPIVersion = "3",
    sAdrsDlm = "/",
    iRowNumber = 1000,
    sRESTactionIssues = "search?fields",
    sRESTactionUsers = "users/search",
    sRESTfields = "issuetype,customfield_10070,timespent,project,resolution,workratio,lastViewed,lastViewed,watches,created,timeestimate,issuelinks,assignee,updated,status,timeoriginalestimate,description,aggregatetimeestimate,summary,subtasks,reporter,duedate,progress,  worklog",
    sSrchDlm = "=",
    iStartCounter = 0,
    iMAxResults = 1,

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
			List_ConvtoTable_1 = Table.FromList(dtIssuesDB, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            GetJiraData_Expanded = Table.ExpandTableColumn(List_ConvtoTable_1, "PaginationFunc", {"Column1"}, {"Issue"})
		in 
			GetJiraData_Expanded
	in
		PaginationFunc,

	ExpandJiraData = 
	let
        Errors_Fixed = Table.RemoveRowsWithErrors(GetJiraData),
		Columns_Removed = Table.RemoveColumns(Errors_Fixed,{"startAt"}),
		Issues_Expanded = Table.ExpandRecordColumn(Columns_Removed, "Issue", {"id", "key", "fields"}, {"Issue.id", "Issue.key", "Issue"}),
		Issues_Expanded_2 = Table.ExpandRecordColumn(Issues_Expanded, "Issue", {"summary", "lastViewed", "issuetype", "watches", "customfield_10070", "subtasks", "created", "timespent", "timeoriginalestimate", "project", "description", "reporter", "resolution", "aggregatetimeestimate", "timeestimate", "duedate","customfield_10015","customfield_10033", "workratio", "progress", "issuelinks", "assignee", "worklog", "updated", "status"}, {"Issue.summary", "Issue.lastViewed", "Issue.issuetype", "Issue.watches", "Issue.customfield_10070", "Issue.subtasks", "Issue.created", "Issue.timespent", "Issue.timeoriginalestimate", "Issue.project", "Issue.description", "Issue.reporter", "Issue.resolution", "Issue.aggregatetimeestimate", "Issue.timeestimate", "Issue.duedate", "Issue.startDate", "Issue.endDate", "Issue.workratio", "Issue.progress", "Issue.issuelinks", "Issue.assignee", "Issue.worklog", "Issue.updated", "Issue.status"}),
		ExpandData = Table.ExpandRecordColumn(Issues_Expanded_2, "Issue.issuetype", {"name"}, {"Issue.issuetype.name"}) 
	in
		ExpandData   
in
	ExpandJiraData