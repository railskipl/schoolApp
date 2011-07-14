pdf.header pdf.margin_box.top_left do
if FileTest.exists?("#{RAILS_ROOT}/public/uploads/image/institute_logo.jpg")
logo = "#{RAILS_ROOT}/public/uploads/image/institute_logo.jpg"
else
logo = "#{RAILS_ROOT}/public/images/application/app_fedena_logo.jpg"
end
@institute_name=Configuration.get_config_value('InstitutionName');
@institute_address=Configuration.get_config_value('InstitutionAddress');
pdf.image logo, :position=>:left, :height=>50, :width=>50
pdf.font "Helvetica" do
      info = [[@institute_name],
        [@institute_address]]
pdf.move_up(50)
pdf.fill_color "97080e"
pdf.table info, :width => 400,
                :align => {0 => :center},
                :position => :center,
                :border_color => "FFFFFF"
      pdf.move_down(20)
      pdf.stroke_horizontal_rule
        end
end
pdf.move_down(125)

subject_no = @subjects.size+1
homework_no = @homework_groups.size+1
@gr = 0
data = Array.new(subject_no+1){Array.new(homework_no+1)}
@max_total = 0
@marks_total = 0
subject_no.times do |i|
@g = 0
    homework_no.times do |j|
        @homework = homework.find_by_subject_id_and_homework_group_id(@subjects[i-1].id,@homework_groups[j-1].id)
        homework_score = homeworkScore.find_by_student_id(@student.id, :conditions=>{:homework_id=>@homework.id})unless @homework.nil?
            data[0][0] = 'Subject'
            data[0][j] = @homework_groups[j-1].name
unless homework_score.nil?
                if @homework_groups[j-1].homework_type == "MarksAndGrades"
                    data[i][j] = "#{homework_score.marks}|#{@homework.maximum_marks}  #{homework_score.grading_level.name}"
                elsif @homework_groups[j-1].homework_type == "Marks"
                    data[i][j] = "#{homework_score.marks}|#{@homework.maximum_marks}" unless @homework.nil?
                else
                    data[i][j] = homework_score.grading_level.name
                    @g = 1
                    @gr = 1
                end
                    data[0][homework_no] = 'Total'
                    unless @g == 1
                    total_score = homeworkScore.new()
                        data[i][homework_no] = total_score.grouped_homework_subject_total(@subjects[i-1],@student,@type)
                        
                    else
                        data[i][homework_no] =''
                    end
if i == 1
                    if @homework_groups[j-1].homework_type == "MarksAndGrades"
                        data[subject_no][j] = @homework_groups[j-1].total_marks(@student)[0]
                        if j < homework_no-1
                            @marks_total = @marks_total + @homework_groups[j-1].total_marks(@student)[0]
                            @max_total = @max_total + @homework_groups[j-1].total_marks(@student)[1]
                        end
                    elsif @homework_groups[j-1].homework_type == "Marks"
                        data[subject_no][j] = @homework_groups[j-1].total_marks(@student)[0]
                        if j < homework_no-1
                            @marks_total = @marks_total + @homework_groups[j-1].total_marks(@student)[0]
                            @max_total = @max_total + @homework_groups[j-1].total_marks(@student)[1]
                        end
                    else
                        data[subject_no][j] = ''
                    end
end
                    
    end
                    data[i][0]= @subjects[i-1].name
                    
                    data[subject_no][0] = 'Total'
end
                    

end
pdf.table data, :width => 500,
                                    :border_color => "000000",
                                    :position => :center,
                                    :row_colors => ["FFFFFF","DDDDDD"],
                                    :align => { 0 => :left, 1 => :center, 2 => :center, 3 =>:center}

pdf.move_down(30)
if @gr == 0
aggregate = @marks_total*100/@max_total.to_f unless @max_total == 0
aggregate=0 if aggregate==nil


pdf.text @student.full_name, :size => 18 ,:at=>[10,620]
pdf.text "homeworkination results" ,:size => 7,:at=>[10,610]
pdf.text "Total marks: #{@marks_total} , Aggregate: " + "%.2f" %aggregate + "%",  :at=>[350,620]
end
pdf.footer [pdf.margin_box.left, pdf.margin_box.bottom + 25] do
     pdf.font "Helvetica" do
        signature = [[""]]
        pdf.table signature, :width => 500,
                :align => {0 => :right,1 => :right},
                :headers => ["Signature"],
                :header_text_color  => "DDDDDD",
                :border_color => "FFFFFF",
                :position => :center
        pdf.move_down(20)
        pdf.stroke_horizontal_rule
    end
end
