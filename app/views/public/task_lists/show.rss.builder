xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{ @public_task_list.name }"

    @public_task_list.tasks.each do |task|
      xml.item do
        xml.title task.name
        xml.link public_project_task_url(@project, task)
      end
    end
  end
end
