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
		ExpanJiraData