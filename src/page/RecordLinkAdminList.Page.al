page 50100 "Record Link Admin List"
{
    PageType = List;
    SourceTable = "Record Link";
    ApplicationArea = All;
    Caption = 'Record Link Administration';
    UsageCategory = Administration;
    Editable = false;
    SourceTableView = sorting("Link ID") order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Link ID"; Rec."Link ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique ID of the record link.';
                }
                field(LinkType; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if this is a Note or a Link.';
                }
                field(Created; Rec.Created)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the note was created.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who created the note.';
                }
                field("Target Table"; TargetTableName)
                {
                    Caption = 'Target Table';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the table this link is attached to.';
                }
                field("Target Record"; TargetRecordDescription)
                {
                    Caption = 'Target Record Info';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the record this link is attached to.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the link.';
                }
                field(URL1; Rec.URL1)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL if the type is Link.';
                }
                field(HasNote; HasNoteValue)
                {
                    Caption = 'Has Note Content';
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the record link contains text content.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportJSON)
            {
                ApplicationArea = All;
                Caption = 'Export to JSON';
                Image = ExportFile;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Exports the selected record links to a JSON file including Base64 encoded notes.';

                trigger OnAction()
                var
                    SelectedRecs: Record "Record Link";
                    RecordLinkMgt: Codeunit "Record Link Mgt.";
                begin
                    CurrPage.SetSelectionFilter(SelectedRecs);
                    RecordLinkMgt.ExportRecordLinks(SelectedRecs);
                end;
            }
            action(ImportJSON)
            {
                ApplicationArea = All;
                Caption = 'Import from JSON';
                Image = Import;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Imports record links from a previously exported JSON file.';

                trigger OnAction()
                var
                    RecordLinkMgt: Codeunit "Record Link Mgt.";
                    FileInStream: InStream;
                    FileName: Text;
                begin
                    if UploadIntoStream('Import JSON File', '', 'JSON Files|*.json', FileName, FileInStream) then
                        RecordLinkMgt.ImportRecordLinks(FileInStream, false);
                end;
            }
            action(DeleteAllNotes)
            {
                ApplicationArea = All;
                Caption = 'Delete All Notes';
                Image = Delete;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Deletes all Record Links of type Note from the system. Warning: Irreversible.';

                trigger OnAction()
                var
                    RecLink: Record "Record Link";
                begin
                    if not Confirm('Are you sure you want to delete ALL Notes? This cannot be undone.') then exit;
                    RecLink.SetRange(Type, RecLink.Type::Note);
                    RecLink.DeleteAll();
                    Message('Notes deleted.');
                end;
            }
        }
    }

    var
        TargetTableName: Text;
        TargetRecordDescription: Text;
        HasNoteValue: Boolean;

    trigger OnAfterGetRecord()
    var
        RecRef: RecordRef;
    begin
        Clear(TargetTableName);
        Clear(TargetRecordDescription);
        HasNoteValue := Rec.Note.HasValue;

        if Rec."Record ID".TableNo = 0 then
            exit;

        if RecRef.Get(Rec."Record ID") then begin
            TargetTableName := RecRef.Caption;
            if RecRef.KeyIndex(1).FieldCount > 0 then
                TargetRecordDescription := Format(RecRef.KeyIndex(1).FieldIndex(1).Value);
        end else
            TargetTableName := Format(Rec."Record ID".TableNo) + ' (Record Deleted)';

    end;
}