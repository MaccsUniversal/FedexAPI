codeunit 50101 "Fedex Setup Init"
{
    procedure Init()
    var
        FedexSetup: Record "Fedex Setup";
    begin
        if FedexSetup.Get('FEDEXAPI') then
            exit;

        FedexSetup.Init();
        FedexSetup.Code := 'FEDEXAPI';
        FedexSetup.Insert()
    end;
}