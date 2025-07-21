codeunit 50111 "Fedex Bundle Items"
{
    [EventSubscriber(ObjectType::Table, Database::"Fedex Bundle Items", OnBeforeInsertEvent, '', true, true)]
    local procedure OnBeforeInsertItem(var Rec: Record "Fedex Bundle Items")
    var
        ItemNo: Record Item;
    begin
        if ItemNo.Get(Rec."FED Item No.") then begin
            Rec.Description := ItemNo.Description;
        end;
    end;
}