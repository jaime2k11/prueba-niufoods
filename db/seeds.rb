# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seeds basicos. Crea usuarios iniciales.
user_emails = ['admin@niufoods.cl', 'test@niufoods.cl']
default_password = 'password123'
begin
  if defined?(User)
    user_emails.each do |email|
      User.find_or_create_by!(email:) do |u|
        u.password = u.password_confirmation = default_password
      end
    end
    puts "Seeds loaded (users)."
  else
    puts "Seeds skipped (User not loaded yet)."
  end
rescue => e
  puts "Seeds skipped (users): #{e.message}"
end

# Restaurantes de referencia
begin
  if defined?(Restaurant)
    restaurants = [
      { code: 'PROV', name: 'Niu Foods Providencia' },
      { code: 'LCON', name: 'Niu Foods Las Condes' },
      { code: 'NUNO', name: 'Niu Foods Ñuñoa' }
    ]
    restaurants.each do |attrs|
      r = Restaurant.find_or_initialize_by(code: attrs[:code])
      r.name = attrs[:name]
      r.save!
    end
    puts "Seeds loaded (restaurants)."
  else
    puts "Seeds skipped (restaurants not loaded yet)."
  end
rescue => e
  puts "Seeds skipped (restaurants): #{e.message}"
end

# Catálogo global de productos del dataset
begin
  if defined?(Product)
    products = [
      { sku: 'SKU-001', name: 'Niu Roll Salmón', price_cents: 8990 },
      { sku: 'SKU-002', name: 'California Ebi', price_cents: 7490 },
      { sku: 'SKU-003', name: 'Avocado Roll', price_cents: 6990 },
      { sku: 'SKU-004', name: 'Nigiri Salmón x2', price_cents: 3990 },
      { sku: 'SKU-005', name: 'Gyozas de Pollo x5', price_cents: 4490 },
      { sku: 'SKU-006', name: 'Edamame', price_cents: 3290 },
      { sku: 'SKU-007', name: 'Bowl Salmón Teriyaki', price_cents: 9990 },
      { sku: 'SKU-008', name: 'Bowl Pollo Teriyaki', price_cents: 8990 },
      { sku: 'SKU-009', name: 'Bebida 350 ml', price_cents: 1990 },
      { sku: 'SKU-010', name: 'Agua Mineral 500 ml', price_cents: 1590 }
    ]
    products.each do |attrs|
      p = Product.find_or_initialize_by(sku: attrs[:sku])
      p.name = attrs[:name]
      p.price_cents = attrs[:price_cents]
      p.save!
    end
    puts "Seeds loaded (products)."
  else
    puts "Seeds skipped (products not loaded yet)."
  end
rescue => e
  puts "Seeds skipped (products): #{e.message}"
end
