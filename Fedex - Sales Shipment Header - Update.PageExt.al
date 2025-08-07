pageextension 99014 "Fedex - Sales Shpt - Update" extends "Posted Sales Shipment - Update"
{
    layout
    {
        addafter("Package Tracking No.")
        {
            field("Fedex Tracking No."; Rec."Fedex Tracking No.")
            {
                ApplicationArea = All;
                Caption = 'Fedex Tracking No.';
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