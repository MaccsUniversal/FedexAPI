pageextension 50106 "Fedex - Sales Order" extends "Sales Order"
{
    layout
    {
        addafter("Package Tracking No.")
        {
            field("Fedex Tracking No."; Rec."Fedex Tracking No.")
            {
                ApplicationArea = All;
                Enabled = false;
                Caption = 'Fedex Tracking No.';
            }

            field("Label Status"; Rec."Label Status")
            {
                ApplicationArea = All;
                Enabled = false;
                Caption = 'Fedex Label Status';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}