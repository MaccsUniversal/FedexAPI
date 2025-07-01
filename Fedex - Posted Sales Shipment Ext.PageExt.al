pageextension 50101 "Fedex - Pstd Sales Shpment" extends "Posted Sales Shipment"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addlast("&Shipment")
        {

            action(CreateLabel)
            {
                Caption = 'Create Label';
                ApplicationArea = Basic, Suite;
                Image = CreateDocuments;

                trigger OnAction()
                var
                    CreateLabel: Codeunit "Fedex - Create Shipment";
                    SalesShipmentHdr: Record "Sales Shipment Header";
                begin
                    SalesShipmentHdr.Copy(Rec);
                    CreateLabel.Run(SalesShipmentHdr);
                    Message('Just Created a Label.')
                end;
            }

            action(UpdateLabel)
            {
                Caption = 'Update Label';
                ApplicationArea = Basic, Suite;
                Image = UpdateXML;

                trigger OnAction()
                begin
                    Message('Just Updated a Label.')
                end;
            }

            action(CancelLabel)
            {
                Caption = 'Cancel Label';
                ApplicationArea = Basic, Suite;
                Image = CancelledEntries;

                trigger OnAction()
                begin
                    Message('Just Cancelled a Label.')
                end;
            }
        }

        addfirst(Category_Category5)
        {
            group(FedexLabels)
            {
                Caption = 'Fedex Labels';
                Image = ReleaseShipment;

                actionref(LabelCreation; CreateLabel)
                {
                }
                actionref(LabelUpdate; UpdateLabel)
                {
                }
                actionref(LabelCancellation; CancelLabel)
                {
                }
            }
        }
    }
}