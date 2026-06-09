export type PassportDetails = {
  given_name?: string | null;
  family_name?: string | null;
  date_of_birth?: string | null;
  gender?: string | null;
  nationality?: string | null;
  passport_number?: string | null;
  passport_expiry?: string | null;
  passport_issuing_country?: string | null;
};

export type UserProfile = {
  id: number;
  email: string;
  is_active: boolean;
  is_email_verified: boolean;
  created_at?: string | null;
  avatar_path?: string | null;
  role_name?: string | null;
  admin?: { full_name?: string; phone?: string | null } | null;
  passenger?: {
    full_name: string;
    phone?: string | null;
    account_status: string;
    passport_image?: string | null;
    passport_details?: PassportDetails | null;
  } | null;
};
