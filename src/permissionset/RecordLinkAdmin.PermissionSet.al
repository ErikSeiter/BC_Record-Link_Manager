permissionset 50100 "RecordLinkAdmin"
{
    Assignable = true;
    Caption = 'Record Link Admin';
    Permissions = tabledata "Record Link" = RIMD,
                  codeunit "Record Link Mgt." = X,
                  page "Record Link Admin List" = X;
}