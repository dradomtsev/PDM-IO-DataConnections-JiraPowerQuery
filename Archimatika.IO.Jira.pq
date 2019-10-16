// This file contains your Data Connector logic
section Archimatika.IO.Jira;

Users                   = Extension.LoadFunction("Users.pqm");
Issues                  = Extension.LoadFunction("Issues.pqm");
Table.ToNavigationTable = Extension.LoadFunction("Table_ToNavigationTable.pqm");

Init = () =>
let
    Source = Json.Document(File.Contents("C:\Users\d.radomtsev\Documents\Power BI Desktop\Custom Connectors\config.json"))
in
    Source;

[DataSource.Kind="Archimatika.IO.Jira", Publish="Archimatika.IO.Jira.Publish"]
shared CreateNavTable = () as table => 
    let 

        //JSONData = Init(),
        //sJiraServiceAddress = Record.Field(JSONData, "sJiraServiceAddress"),

        iRateLimit = 50,
        sJiraServiceAddress = "https://archimatika.atlassian.net/rest/api",
        sAPIVersion = 3,
        sAdrsDlm = "/",
        iRowNumber = 1000,
        sRESTactionIssues = "search?fields",
        sRESTactionUsers = "users/search",
        sRESTfields = "issuetype,customfield_10070,timespent,project,resolution,workratio,lastViewed,lastViewed,watches,created,timeestimate,issuelinks,assignee,updated,status,timeoriginalestimate,description,aggregatetimeestimate,summary,subtasks,reporter,duedate,progress,  worklog",
        sSrchDlm = "=",
        iStartCounter = 0,
        iMAxResults = 1,

		objects = #table(
            {"Name",            "Key",              "Data",                                 "ItemKind", "ItemName", "IsLeaf"},{
            {"Issues+Worklog",	"Issues+Worklog",   Issues(iRateLimit, sJiraServiceAddress, sAPIVersion, sAdrsDlm, sRESTactionIssues, sRESTfields, sSrchDlm, iStartCounter, iMAxResults),   "Table",    "Table",	true},            
            {"Users",			"Users",			Users(iRateLimit, sJiraServiceAddress, sAPIVersion, sAdrsDlm, iRowNumber, sRESTactionUsers, sRESTfields, sSrchDlm, iStartCounter, iMAxResults),	        "Table",    "Table",	true}
            }),
        NavTable = Table.ToNavigationTable(objects, {"Key"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        NavTable;

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name),
        asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

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
