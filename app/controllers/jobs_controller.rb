class JobsController < ApplicationController
  before_filter :find_project, except: [:enabled]

  def index
    @jobs = @project.jobs.non_deploy.page(params[:page])
  end

  def new
    @job = Job.new
  end

  def create
    job_service = JobService.new(@project, current_user)
    command_ids = command_params[:ids].select(&:present?)

    @job = job_service.execute!(
      job_params[:commit].strip, command_ids,
      job_params[:command].strip.presence
    )

    if @job.persisted?
      JobExecution.start_job(job_params[:commit].strip, @job)
      redirect_to project_job_path(@project, @job)
    else
      render :new
    end
  end

  def show
    @job = Job.find(params[:id])
    respond_to do |format|
      format.html
      format.text do
        datetime = @job.updated_at.strftime("%Y%m%d_%H%M%Z")
        send_data @job.output,
          type: 'text/plain',
          filename: "#{@project.repo_name}-#{@job.id}-#{datetime}.log"
      end
    end
  end

  def enabled
    if JobExecution.enabled
      head :no_content
    else
      head :accepted
    end
  end

  private

  def job_params
    params.require(:job).permit(:commit, :command)
  end

  def command_params
    params.require(:commands).permit(ids: [])
  end

  def find_project
    @project = Project.find(params[:project_id])
  end
end
