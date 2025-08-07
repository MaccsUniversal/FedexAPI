pageextension 99013 "Fedex - Sales Order" extends "Sales Order"
{
    layout
    {
        addafter("Package Tracking No.")
        {
            field("Fedex Tracking No."; Rec."Fedex Tracking No.")
            {

                ApplicationArea = All;
                Enabled = isEnabled;
                Caption = 'Fedex Tracking No.';

            }

            field("Label Status"; Rec."Label Status")
            {
                ApplicationArea = All;
                Enabled = isEnabled;
                Caption = 'Fedex Label Status';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnOpenPage()
    begin
        if FedexSetup.Find('-') then
            FedexSetup.FindSet();

        if FedexSetup.EnableFields = true then
            isEnabled := true;
    end;

    var
        FedexSetup: Record "Fedex Setup";
        isEnabled: Boolean;
}