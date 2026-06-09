/** SessionStorage key for selected flight offer before checkout. */
export const PENDING_OFFER_STORAGE_KEY = "mosafer_pending_offer";
export const PENDING_ADULTS_STORAGE_KEY = "mosafer_pending_adults";

export type FlightOffer = {
  offer_id: string;
  provider_flight_id: string;
  origin_iata: string;
  destination_iata: string;
  carrier_code: string;
  carrier_name?: string | null;
  flight_number: string;
  departure_at: string;
  arrival_at: string;
  total_price: string | number | null;
  currency: string | null;
  cabin_class?: string | null;
  baggage_allowance?: string | null;
  departure_terminal?: string | null;
  source?: string;
};

export type FlightSearchResponse = {
  items: FlightOffer[];
  total: number;
  skip: number;
  limit: number;
};

export type BookingPassengerInput = {
  title: string;
  given_name: string;
  family_name: string;
  date_of_birth: string;
  gender: string;
  nationality: string;
  passport_number: string;
  passport_expiry: string;
  passport_issuing_country: string;
  seat?: string;
};

export type FlightSummary = {
  carrier_code: string;
  flight_number: string;
  origin_iata: string;
  destination_iata: string;
  departure_at: string;
  arrival_at: string;
};

export type CheckoutSessionDetail = {
  id: number;
  status: string;
  seats: string[];
  adults_count: number;
  cabin_class: string | null;
  passenger_details_required: boolean;
  passengers_submitted: boolean;
  carrier_name: string | null;
  reservation_id: number | null;
  flight: FlightSummary;
};

export type ReservationDetail = {
  id: number;
  status: string;
  seat: string;
  seats?: string[];
  pnr: string | null;
  cabin_class: string | null;
  adults_count: number;
  ticket_number: string | null;
  ticket_status: string | null;
  carrier_name: string | null;
  passenger_details_required: boolean;
  passenger_details_completed_at: string | null;
  flight: FlightSummary;
  passengers: Array<{
    title: string;
    given_name: string;
    family_name: string;
    passport_number: string;
    seat?: string | null;
    passenger_ticket_number?: string | null;
    qr_code?: string | null;
  }>;
};
