class SharedPackagesController < ApplicationController
  def index
    @packages = Package.shared.where("unit_id != #{current_unit.id}")
    pb_ids = []
    @packages.each do |p|
      pb_ids << p.package_branch_id
    end
    @package_branches = PackageBranch.find(pb_ids.uniq)
    @other_units = Unit.from_other_unit(current_unit)
  end
  
  # Updates the shared package resource by adding a new instance of that package
  # to the current unit.  This is very basic and gets complicated when that package
  # has dependencies.  This still needs to be sorted out.
  def import
    @shared_package = Package.shared.where("unit_id != #{current_unit.id}").find(params[:id])
    @package = Package.import_package(current_unit, @shared_package)
    
    respond_to do |format|
      if @package.save
        flash[:notice] = "Successfully imported #{@shared_package.display_name} (#{@shared_package.version})"
        format.html { redirect_to edit_package_path(@package.to_params) }
      else
        flash[:error] = "Unable to import #{@shared_package.display_name} (#{@shared_package.version})"
        format.html { redirect_to shared_packages_path(current_unit) }
      end
    end
  end
  
  # Import two or more packages from other units,
  # after import default to staging enviroment, and package shared status to false
  def import_multiple
    shared_packages = Package.shared.where("unit_id != #{current_unit.id}").find(params[:selected_records])
    results = []
    shared_packages.each do |shared_package|
      package = Package.import_package(current_unit, shared_package)
      results << package.save
    end
    respond_to do |format|
      if results.include?(false)
        flash[:error] = "Failed to import packages"
        format.html { redirect_to shared_packages_path(current_unit) }
      else
        flash[:notice] = "Successfully imported packages"
        # upon success redirect to staging package index page, change current_environment
        params[:eid] = 1
        format.html { redirect_to packages_path(current_unit) }
      end
    end
  end
  
  private
  # This controller is a bit of an oddball -- it actually edits Package records,
  # so it authorizes based on a Package instance.  We just grab the first 
  # package from this unit and see if we can act upon it -- we use a record 
  # instead of the Package class to give unit context.
  def load_singular_resource
    @shared_package = Package.where(:unit_id => current_unit.id).limit(1).first
  end
  
  def authorize_resource
    authorize! params[:action], @shared_package
  end
end
