require 'rails_helper'

RSpec.describe TaskReminderJob, :type => :job do

  let(:test_user) { create(:normal_user) }
  let(:test_task) { create(:task, :assigned_to_user => test_user, :send_reminder => true, :complete_by => Time.now+1.day) }

  before(:each) do
    Task.destroy_all
    Message.destroy_all
    create(:normal_user, :first_name => 'system',
    :last_name => 'user',
    :email => 'system.user@example.com') if User.where('first_name = ? AND last_name = ?', 'system', 'user').count == 0
  end

  it 'sends' do
    test_task.save!
    TaskReminderJob.new(1, PriorityType.first).run

    expect(Message.where(:to_user => test_user).count).to eq(1)
  end

  it 'no reminder' do
    test_task.update!(:send_reminder => false)
    TaskReminderJob.new(1,PriorityType.first).run

    expect(Message.count).to eq(0)
  end

  it 'wrong states' do
    test_task.update!(:state => 'completed')
    TaskReminderJob.new(1,PriorityType.first).run

    expect(Message.count).to eq(0)
  end

  it 'wrong due date' do
    test_task.update!(:complete_by => Time.now+5.days)
    TaskReminderJob.new(1,PriorityType.first).run

    expect(Message.count).to eq(0)
  end
  it 'wrong days from now' do
    TaskReminderJob.new(10,PriorityType.first).run

    expect(Message.count).to eq(0)
  end

  it '.prepare' do
    expect(Rails.logger).to receive(:info).with("Executing TaskReminderJob at #{Time.now.to_s} for tasks due in 1 days.")
    TaskReminderJob.new(1, PriorityType.first).prepare
  end

  it '.check' do
    expect{TaskReminderJob.new(1,nil).check}.to raise_error(ArgumentError, "priority_type can't be nil ")
    expect{TaskReminderJob.new(nil,PriorityType.first).check}.to raise_error(ArgumentError, "days_from_now can't be nil ")
  end
end