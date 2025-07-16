require "application_system_test_case"

class AssignmentsTest < ApplicationSystemTestCase
  setup do
    @assignment = assignments(:one)
  end

  test "visiting the index" do
    visit assignments_url
    assert_selector "h1", text: "Assignments"
  end

  test "should create assignment" do
    visit assignments_url
    click_on "New assignment"

    check "Active" if @assignment.active
    fill_in "Ccs", with: @assignment.ccs
    fill_in "Ccs k", with: @assignment.ccs_k
    fill_in "Ccs m", with: @assignment.ccs_m
    check "Ci" if @assignment.ci
    fill_in "Ct", with: @assignment.ct
    fill_in "Majtes", with: @assignment.majtes
    fill_in "Place", with: @assignment.place
    fill_in "Role", with: @assignment.role
    fill_in "Status", with: @assignment.status
    fill_in "Tietes", with: @assignment.tietes
    fill_in "Vcs", with: @assignment.vcs
    fill_in "Vcs a", with: @assignment.vcs_a
    fill_in "Vcs c", with: @assignment.vcs_c
    fill_in "Vcs p", with: @assignment.vcs_p
    fill_in "Vcs t", with: @assignment.vcs_t
    fill_in "Vt", with: @assignment.vt
    click_on "Create Assignment"

    assert_text "Assignment was successfully created"
    click_on "Back"
  end

  test "should update Assignment" do
    visit assignment_url(@assignment)
    click_on "Edit this assignment", match: :first

    check "Active" if @assignment.active
    fill_in "Ccs", with: @assignment.ccs
    fill_in "Ccs k", with: @assignment.ccs_k
    fill_in "Ccs m", with: @assignment.ccs_m
    check "Ci" if @assignment.ci
    fill_in "Ct", with: @assignment.ct
    fill_in "Majtes", with: @assignment.majtes
    fill_in "Place", with: @assignment.place
    fill_in "Role", with: @assignment.role
    fill_in "Status", with: @assignment.status
    fill_in "Tietes", with: @assignment.tietes
    fill_in "Vcs", with: @assignment.vcs
    fill_in "Vcs a", with: @assignment.vcs_a
    fill_in "Vcs c", with: @assignment.vcs_c
    fill_in "Vcs p", with: @assignment.vcs_p
    fill_in "Vcs t", with: @assignment.vcs_t
    fill_in "Vt", with: @assignment.vt
    click_on "Update Assignment"

    assert_text "Assignment was successfully updated"
    click_on "Back"
  end

  test "should destroy Assignment" do
    visit assignment_url(@assignment)
    click_on "Destroy this assignment", match: :first

    assert_text "Assignment was successfully destroyed"
  end
end
