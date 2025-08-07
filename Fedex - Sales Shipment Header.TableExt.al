tableextension 99012 "Fedex - Sales Shipment Header" extends "Sales Shipment Header"
{
    fields
    {
        field(50000; "Fedex Tracking No."; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Fedex Tarcking No.';
        }

        field(50001; "Label Status"; Enum "Fedex Label Status")
        {
            DataClassification = ToBeClassified;
            Caption = 'Fedex Label Status';
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }
}