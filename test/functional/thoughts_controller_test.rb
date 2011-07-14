require 'test_helper'

class ThoughtsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:thoughts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create thought" do
    assert_difference('Thought.count') do
      post :create, :thought => { }
    end

    assert_redirected_to thought_path(assigns(:thought))
  end

  test "should show thought" do
    get :show, :id => thoughts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => thoughts(:one).to_param
    assert_response :success
  end

  test "should update thought" do
    put :update, :id => thoughts(:one).to_param, :thought => { }
    assert_redirected_to thought_path(assigns(:thought))
  end

  test "should destroy thought" do
    assert_difference('Thought.count', -1) do
      delete :destroy, :id => thoughts(:one).to_param
    end

    assert_redirected_to thoughts_path
  end
end
