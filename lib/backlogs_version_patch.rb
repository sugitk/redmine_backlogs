require_dependency 'version'

module Backlogs
  module VersionPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        has_one :sprint_burndown, :class_name => RbSprintBurndown, :dependent => :destroy
        belongs_to :release, :class_name => 'RbRelease', :foreign_key => 'release_id'
        belongs_to :rbteam, :class_name => 'User', :foreign_key => 'rbteam_id'

        after_save :clear_burndown

        include Backlogs::ActiveRecord::Attributes
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def clear_burndown
        self.burndown.touch!
        true
      end

      # load on demand
      def burndown
        unless self.new_record? || self.sprint_burndown
          self.sprint_burndown = self.build_sprint_burndown
          self.sprint_burndown.save!
        end
        self.sprint_burndown
      end

      def days
        #return Day objects. Version stores start and effective date without timezone. These are used to filter history entries and thus the zone of these days are those of the history dates
        return nil unless self.sprint_start_date && self.effective_date
        (self.sprint_start_date - 1 .. self.effective_date).to_a.select{|d| Backlogs.setting[:include_sat_and_sun] || ![0,6].include?(d.wday)}
      end

      def has_burndown?
        return (self.days || []).size != 0
      end

      def assignable_releases
        RbRelease.open
      end

      def rbteam
        Group.find(rbteam_id)
      rescue
        nil
      end

      def rbteam_id=(tid)
        write_attribute(:rbteam_id, tid)
      end

      def name_team
        return name unless rbteam
        return "#{name} (#{rbteam.name})"
      end

    end
  end
end

Version.send(:include, Backlogs::VersionPatch) unless Version.included_modules.include? Backlogs::VersionPatch
