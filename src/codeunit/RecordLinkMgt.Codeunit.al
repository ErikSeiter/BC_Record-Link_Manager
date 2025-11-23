codeunit 50100 "Record Link Mgt."
{
    Access = Public;

    procedure ExportRecordLinks(var RecordLink: Record "Record Link")
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        JArray: JsonArray;
        JObject: JsonObject;
        FileName: Text;
    begin
        if not RecordLink.FindSet() then
            Error('No record links selected to export.');

        repeat
            Clear(JObject);
            if TryCreateRecordLinkJsonObject(RecordLink, JObject) then
                JArray.Add(JObject);
        until RecordLink.Next() = 0;

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        JArray.WriteTo(OutStream);

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := 'RecordLinks_Export_' + Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>') + '.json';
        DownloadFromStream(InStream, 'Export Record Links', '', 'JSON Files (*.json)|*.json', FileName);
    end;

    procedure ImportRecordLinks(var FileInStream: InStream; DeleteExisting: Boolean)
    var
        RecordLink: Record "Record Link";
        JArray: JsonArray;
        JToken: JsonToken;
        JObject: JsonObject;
        JsonText: Text;
        ImportCount: Integer;
        ErrorCount: Integer;
    begin
        FileInStream.ReadText(JsonText);
        if not JArray.ReadFrom(JsonText) then
            Error('Invalid JSON format.');

        if DeleteExisting then begin
            RecordLink.SetRange(Type, RecordLink.Type::Note);
            RecordLink.DeleteAll();
        end;

        foreach JToken in JArray do begin
            JObject := JToken.AsObject();
            if ImportSingleRecordLink(JObject) then
                ImportCount += 1
            else
                ErrorCount += 1;
        end;

        Message('Import Finished.\nImported: %1\nErrors/Skipped: %2', ImportCount, ErrorCount);
    end;

    local procedure TryCreateRecordLinkJsonObject(var RecordLink: Record "Record Link"; var JObject: JsonObject): Boolean
    var
        Base64Convert: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        NoteInStream: InStream;
        KeyValues: JsonArray;
        i: Integer;
        Base64Text: Text;
    begin
        JObject.Add('LinkID', RecordLink."Link ID");
        JObject.Add('Description', RecordLink.Description);
        JObject.Add('URL1', RecordLink.URL1);
        JObject.Add('Type', Format(RecordLink.Type));
        JObject.Add('UserID', RecordLink."User ID");
        JObject.Add('Created', RecordLink.Created);

        if RecordLink.Note.HasValue then begin
            RecordLink.CalcFields(Note);
            RecordLink.Note.CreateInStream(NoteInStream, TextEncoding::UTF8);
            Base64Text := Base64Convert.ToBase64(NoteInStream);
            JObject.Add('NoteBase64', Base64Text);
        end else
            JObject.Add('NoteBase64', '');


        if not RecRef.Get(RecordLink."Record ID") then
            exit(false);

        JObject.Add('TableNo', RecRef.Number);

        KeyRef := RecRef.KeyIndex(1);
        for i := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(i);
            KeyValues.Add(Format(FieldRef.Value, 0, 9));
        end;
        JObject.Add('KeyValues', KeyValues);

        exit(true);
    end;

    local procedure ImportSingleRecordLink(JObject: JsonObject): Boolean
    var

        RecordLink: Record "Record Link";
        Base64Convert: Codeunit "Base64 Convert";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyRef: KeyRef;
        NoteOutStream: OutStream;
        JToken: JsonToken;
        JArrayKeys: JsonArray;
        TableNo: Integer;
        LinkID: Integer;
        i: Integer;
        KeyValue: Text;
        Base64Text: Text;
    begin
        JObject.Get('LinkID', JToken);
        LinkID := JToken.AsValue().AsInteger();

        JObject.Get('TableNo', JToken);
        TableNo := JToken.AsValue().AsInteger();

        RecRef.Open(TableNo);
        KeyRef := RecRef.KeyIndex(1);

        JObject.Get('KeyValues', JToken);
        JArrayKeys := JToken.AsArray();

        if KeyRef.FieldCount <> JArrayKeys.Count then
            exit(false);

        for i := 1 to JArrayKeys.Count do begin
            JArrayKeys.Get(i - 1, JToken);
            KeyValue := JToken.AsValue().AsText();

            FieldRef := KeyRef.FieldIndex(i);
            EvaluateGenericField(FieldRef, KeyValue);
        end;

        if not RecRef.Find('=') then
            exit(false);
        if RecordLink.Get(LinkID) then
            RecordLink.Delete();

        RecordLink.Init();
        RecordLink."Link ID" := LinkID;
        RecordLink."Record ID" := RecRef.RecordId;

        if JObject.Get('Description', JToken) then RecordLink.Description := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RecordLink.Description));
        if JObject.Get('URL1', JToken) then RecordLink.URL1 := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RecordLink.URL1));
        if JObject.Get('UserID', JToken) then RecordLink."User ID" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RecordLink."User ID"));
        if JObject.Get('Type', JToken) then Evaluate(RecordLink.Type, JToken.AsValue().AsText());
        RecordLink.Company := CompanyName;
        RecordLink.Created := CurrentDateTime;

        RecordLink.Insert();

        if JObject.Get('NoteBase64', JToken) then begin
            Base64Text := JToken.AsValue().AsText();
            if Base64Text <> '' then begin
                RecordLink.Note.CreateOutStream(NoteOutStream, TextEncoding::UTF8);
                Base64Convert.FromBase64(Base64Text, NoteOutStream);
                RecordLink.Modify();
            end;
        end;

        exit(true);
    end;

    local procedure EvaluateGenericField(var FldRef: FieldRef; ValueText: Text)
    var
        IntVal: Integer;
        DecVal: Decimal;
        DateVal: Date;
        BoolVal: Boolean;
        GuidVal: Guid;
    begin
        case FldRef.Type of
            FieldType::Integer, FieldType::Option:
                begin
                    Evaluate(IntVal, ValueText);
                    FldRef.Value := IntVal;
                end;
            FieldType::Decimal:
                begin
                    Evaluate(DecVal, ValueText);
                    FldRef.Value := DecVal;
                end;
            FieldType::Date:
                begin
                    Evaluate(DateVal, ValueText);
                    FldRef.Value := DateVal;
                end;
            FieldType::Boolean:
                begin
                    Evaluate(BoolVal, ValueText);
                    FldRef.Value := BoolVal;
                end;
            FieldType::Code, FieldType::Text:
                FldRef.Value := ValueText;
            FieldType::GUID:
                begin
                    Evaluate(GuidVal, ValueText);
                    FldRef.Value := GuidVal;
                end;
        end;
    end;
}