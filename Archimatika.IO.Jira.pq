// This file contains your Data Connector logic
section Archimatika.IO.Jira;

[DataSource.Kind="Archimatika.IO.Jira", Publish="Archimatika.IO.Jira.Publish"]
shared Archimatika.IO.Jira.Contents = (optional message as text) =>
    let
        _message = if (message <> null) then message else "(no message)",
        a = "Hello from Archimatika.IO.Jira: " & _message
    in
        a;

// Data Source Kind description
Archimatika.IO.Jira = [
    Authentication = [
        // Key = [],
        // UsernamePassword = [],
        // Windows = [],
        Implicit = []
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
