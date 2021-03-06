require 'spec_helper'

describe AwsPricing::RdsPriceList do
  before(:all) do
    @pricing = AwsPricing::RdsPriceList.new
    @region_name = %w(us-east us-west us-west-2 eu-ireland apac-sin apac-syd apac-tokyo sa-east-1)
    @db_types = [:mysql, :oracle, :oracle_byol, :sqlserver, :sqlserver_express, :sqlserver_web, :sqlserver_byol]
  end

  describe 'new' do
    it 'RdsPriceList.new should return the valid response', broken: true do
      @pricing.regions.each do |region|
        # response should have valid region
        expect(@region_name).to include(region.name)
        # Result have valid db name
        expect(@db_types).to include(region.rds_instance_types.first.category_types.first.name)
        # values should not be nil
        region.rds_instance_types.first.category_types.first.ondemand_price_per_hour.should_not be_nil
        region.rds_instance_types.first.category_types.first.light_price_per_hour_1_year.should_not be_nil
        region.rds_instance_types.first.category_types.first.medium_price_per_hour_1_year.should_not be_nil
        region.rds_instance_types.first.category_types.first.heavy_price_per_hour_1_year.should_not be_nil
      end
    end
  end

  describe '::get_api_name' do
    it "raises an UnknownTypeError on an unexpected instance type" do
      expect {
        AwsPricing::RdsInstanceType::get_name 'QuantumODI', 'huge'
      }.to raise_error(AwsPricing::UnknownTypeError)
    end
  end

  describe 'get_breakeven_months' do 
    it "test_fetch_all_breakeven_months" do
      @pricing.regions.each do |region|
        region.rds_instance_types.each do |instance|
          [:year1, :year3].each do |term|
             [:light, :medium, :heavy].each do |res_type|
               [:mysql, :postgresql, :oracle_se1, :oracle_se, :oracle_ee, :sqlserver_se, :sqlserver_ee].each do |db|
                  if db == :postgresql
                    if :heavy
                      AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
                        next if not instance.available?(db, res_type, deploy_type == :multiaz, false)
                        instance.get_breakeven_month(db, res_type, term, deploy_type == :multiaz, false).should_not be_nil
                      end
                    end
                  else
                    AwsPricing::DatabaseType.get_available_types(db).each do |deploy_type|
                      if deploy_type == :byol_multiaz
                        next if not instance.available?(db, res_type, true, true)
                        instance.get_breakeven_month(db, res_type, term, true, true).should_not be_nil
                      else 
                        next if not instance.available?(db, res_type, deploy_type == :multiaz, deploy_type == :byol)
                        instance.get_breakeven_month(db, res_type, term, deploy_type == :multiaz, deploy_type == :byol).should_not be_nil
                      end  
                    end
                  end                      
               end
             end
          end          
        end
      end
    end
  end
end