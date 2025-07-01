enum 50102 "Fedex PickUp Types"
{
    Extensible = true;

    value(0; contact_fedex_to_schedule)
    {
        Caption = 'Contact Fedex to schedule';
    }

    value(1; droppoff_at_fedex_location)
    {
        Caption = 'Dropoff at Fedex location';
    }

    value(2; use_scheduled_pickup)
    {
        Caption = 'Use scheduled pickup';
    }
}