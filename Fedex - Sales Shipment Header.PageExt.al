pageextension 99015 "Fedex - Pstd Sales Shpment" extends "Posted Sales Shipment"
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
        addlast("&Shipment")
        {

            action("CreateLabel")
            {
                Caption = 'Create Label';
                ApplicationArea = Basic, Suite;
                Image = CreateDocuments;


                trigger OnAction()
                var
                    CreateLabel: Codeunit "Fedex - Create Label";
                    SalesShipmentHdr: Record "Sales Shipment Header";
                    SalesOrder: Record "Sales Header";
                    SalesShipmentLines: Record "Sales Shipment Line";
                begin
                    if not SalesOrder.Get(SalesOrder."Document Type"::Order, Rec."Order No.") then begin
                        Error('This shipment has been already been invoiced.');
                    end else begin
                        if SalesOrder."Label Status" = SalesOrder."Label Status"::Generated then
                            Error('Labels have already been created. Please check print server files to confirm.');
                    end;

                    SalesShipmentLines.Copy(GetSalesShipmentLines(Rec));
                    CreateLabel.SetShipmentLines(SalesShipmentLines);
                    SalesShipmentHdr.Copy(Rec);
                    CreateLabel.Run(SalesShipmentHdr);
                end;
            }

            action(CancelLabel)
            {
                Caption = 'Cancel Label';
                ApplicationArea = Basic, Suite;
                Image = CancelledEntries;

                trigger OnAction()
                var
                    CancelLabel: Codeunit "Fedex - Cancel Labels";
                    SalesShipmentHdr: Record "Sales Shipment Header";
                begin
                    SalesShipmentHdr.Copy(Rec);
                    CancelLabel.Run(SalesShipmentHdr);
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
                actionref(LabelCancellation; CancelLabel)
                {
                }
            }
        }
    }

    local procedure GetSalesShipmentLines(ShipmentHdr: Record "Sales Shipment Header") ShipmentLines: Record "Sales Shipment Line"
    begin
        ShipmentLines.Reset();
        ShipmentLines.SetFilter(ShipmentLines."Order No.", ShipmentHdr."Order No.");
        ShipmentLines.SetFilter(ShipmentLines."Qty. Shipped Not Invoiced", '>0');
        ShipmentLines.SetFilter(ShipmentLines."Shipment Date", Format(ShipmentHdr."Shipment Date"));
        ShipmentLines.SetFilter(Type, Format(ShipmentLines.Type::Item));
        ShipmentLines.FindSet();
        exit(ShipmentLines);
    end;
}