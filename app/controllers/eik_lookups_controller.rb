# Autofill invoice details from a Bulgarian ЕИК (used on the checkout page).
class EikLookupsController < ApplicationController
  def show
    result = BulgarianTradeRegister::Lookup.find(params[:id])
    if result
      render json: {
        found: true,
        company: result.company_legal_name,
        address: result.company_address,
        vat: result.vat_number,
        mol: result.mol,
      }
    else
      render json: { found: false }, status: :not_found
    end
  end
end
