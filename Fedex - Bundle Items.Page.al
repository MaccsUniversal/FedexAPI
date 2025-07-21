page 50107 "Fedex - Bundle Items"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Fedex Bundle Items";
    DelayedInsert = true;
    Caption = 'Fedex Bundle Items';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Item No."; Rec."FED Item No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    Caption = 'Item No.';
                }

                field("Description"; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }

                field("Pcs. Per Parcel"; Rec."Pcs. Per Parcel")
                {
                    Caption = 'Pcs. Per Parcel';
                    ApplicationArea = All;
                    ToolTip = 'Enter a minimum quantity that will go into 1 parcel.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin

                end;
            }
        }
    }

    var
        myInt: Integer;
}