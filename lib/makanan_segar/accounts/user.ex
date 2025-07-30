defmodule MakananSegar.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :address, :string
    field :profile_image, :string
    field :is_admin, :boolean, default: false
    field :is_vendor, :boolean, default: false
    field :confirmed_at, :utc_datetime
    field :authenticated_at, :utc_datetime, virtual: true

    # Vendor business fields
    field :business_name, :string
    field :phone, :string
    field :business_description, :string
    field :business_hours, :string
    field :business_type, :string
    field :business_registration_number, :string
    field :website, :string
    field :social_media, :map

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registering or changing the email.

  It requires the email to change otherwise an error is added.

  ## Options

    * `:validate_unique` - Set to false if you don't want to validate the
      uniqueness of the email, useful when displaying live validations.
      Defaults to `true`.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A user changeset for registration with magic link authentication.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :name])
    |> validate_required([:email])
    |> validate_email(opts)
    |> validate_name()
  end

  @doc """
  A user changeset for updating profile information.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :name,
      :address,
      :profile_image,
      :business_name,
      :phone,
      :business_description,
      :business_hours,
      :business_type,
      :business_registration_number,
      :website,
      :social_media
    ])
    |> validate_required([:name])
    |> validate_name()
    |> validate_address()
    |> validate_vendor_fields()
  end

  @doc """
  A user changeset for admin operations (updating roles).
  """
  def role_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_admin, :is_vendor])
    |> validate_inclusion(:is_admin, [true, false])
    |> validate_inclusion(:is_vendor, [true, false])
  end

  defp validate_email(changeset, opts) do
    changeset =
      changeset
      |> validate_required([:email])
      |> validate_format(:email, ~r/^[^@,;\s]+@[^@,;\s]+$/,
        message: "must have the @ sign and no spaces"
      )
      |> validate_length(:email, max: 160)

    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:email, MakananSegar.Repo)
      |> unique_constraint(:email)
      |> validate_email_changed()
    else
      changeset
    end
  end

  defp validate_email_changed(changeset) do
    if get_field(changeset, :email) && get_change(changeset, :email) == nil do
      add_error(changeset, :email, "did not change")
    else
      changeset
    end
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, min: 2, max: 100)
    |> validate_format(:name, ~r/^[a-zA-Z\s]+$/, message: "must contain only letters and spaces")
  end

  defp validate_address(changeset) do
    address = get_change(changeset, :address) || get_field(changeset, :address)

    if address do
      changeset
      |> validate_length(:address, min: 10, max: 500)
      |> validate_malaysia_address()
    else
      changeset
    end
  end

  defp validate_malaysia_address(changeset) do
    address = get_change(changeset, :address) || get_field(changeset, :address)

    # Basic validation for Malaysian addresses
    malaysian_states = [
      "johor",
      "kedah",
      "kelantan",
      "malacca",
      "melaka",
      "negeri sembilan",
      "pahang",
      "penang",
      "perak",
      "perlis",
      "sabah",
      "sarawak",
      "selangor",
      "terengganu",
      "kuala lumpur",
      "labuan",
      "putrajaya"
    ]

    address_lower = String.downcase(address || "")

    has_malaysian_state =
      Enum.any?(malaysian_states, fn state ->
        String.contains?(address_lower, state)
      end)

    if has_malaysian_state do
      changeset
    else
      add_error(changeset, :address, "must be a valid Malaysian address")
    end
  end

  defp validate_vendor_fields(changeset) do
    changeset
    |> validate_phone()
    |> validate_business_name()
    |> validate_website()
    |> validate_business_type()
  end

  defp validate_phone(changeset) do
    phone = get_change(changeset, :phone) || get_field(changeset, :phone)

    if phone do
      changeset
      |> validate_length(:phone, min: 10, max: 15)
      |> validate_format(:phone, ~r/^[0-9+\-\s()]*$/,
        message: "must contain only numbers, spaces, +, -, and parentheses"
      )
    else
      changeset
    end
  end

  defp validate_business_name(changeset) do
    business_name = get_change(changeset, :business_name)

    if business_name do
      changeset
      |> validate_length(:business_name, min: 2, max: 100)
    else
      changeset
    end
  end

  defp validate_website(changeset) do
    website = get_change(changeset, :website)

    if website do
      changeset
      |> validate_format(:website, ~r/^https?:\/\//,
        message: "must start with http:// or https://"
      )
    else
      changeset
    end
  end

  defp validate_business_type(changeset) do
    business_type = get_change(changeset, :business_type)

    if business_type do
      valid_types = ["fruits", "vegetables", "fish", "meat", "dairy", "bakery", "spices", "other"]

      changeset
      |> validate_inclusion(:business_type, valid_types,
        message: "must be one of: #{Enum.join(valid_types, ", ")}"
      )
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Returns true if the user is an admin.
  """
  def admin?(%__MODULE__{is_admin: is_admin}), do: is_admin

  @doc """
  Returns true if the user is a vendor.
  """
  def vendor?(%__MODULE__{is_vendor: is_vendor}), do: is_vendor

  @doc """
  Returns true if the user is confirmed.
  """
  def confirmed?(%__MODULE__{confirmed_at: confirmed_at}), do: not is_nil(confirmed_at)
end
