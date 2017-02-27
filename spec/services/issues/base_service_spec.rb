require 'spec_helper.rb'

describe Issues::BaseService, services: true do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    project.team << [user, :developer]
  end

  describe "for resolving discussions" do
    let(:discussion) { Discussion.new([create(:diff_note_on_merge_request, project: project, note: "Almost done")]) }
    let(:merge_request) { discussion.noteable }
    let(:other_merge_request) { create(:merge_request, source_project: project, source_branch: "other") }

    describe "#discussions_to_resolve" do
      it "contains a single discussion when matching merge request and discussion are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion.id,
          merge_request_for_resolving_discussions: merge_request.iid
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id)
      end

      it "contains all discussions when only a merge request is passed" do
        second_discussion = Discussion.new([create(:diff_note_on_merge_request,
                                                  noteable: merge_request,
                                                  project: merge_request.target_project,
                                                  line_number: 15)])
        service = described_class.new(
          project,
          user,
          merge_request_for_resolving_discussions: merge_request.iid
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id, second_discussion.id)
      end

      it "contains only unresolved discussions" do
        second_discussion = Discussion.new([create(:diff_note_on_merge_request, :resolved,
                                                   noteable: merge_request,
                                                   project: merge_request.target_project,
                                                   line_number: 15,
                                                  )])
        service = described_class.new(
          project,
          user,
          merge_request_for_resolving_discussions: merge_request.iid
        )
        # We need to compare discussion id's because the Discussion-objects are rebuilt
        # which causes the object-id's not to be different.
        discussion_ids = service.discussions_to_resolve.map(&:id)

        expect(discussion_ids).to contain_exactly(discussion.id)
      end

      it "is empty when a discussion and another merge request are passed" do
        service = described_class.new(
          project,
          user,
          discussion_to_resolve: discussion.id,
          merge_request_for_resolving_discussions: other_merge_request.iid
        )

        expect(service.discussions_to_resolve).to be_empty
      end
    end
  end
end
