require 'test_helper'

class UploadsControllerTest < ActionController::TestCase
  context "The uploads controller" do
    setup do
      @user = Factory.create(:user)
      CurrentUser.user = @user
      CurrentUser.ip_addr = "127.0.0.1"
    end
    
    teardown do
      CurrentUser.user = nil
      CurrentUser.ip_addr = nil
    end
    
    context "new action" do
      should "render" do
        get :new, {}, {:user_id => @user.id}
        assert_response :success
      end
      
      context "for a post that has already been uploaded" do
        setup do
          @post = Factory.create(:post, :source => "aaa")
        end
        
        should "initialize the post" do
          get :new, {:url => "aaa"}, {:user_id => @user.id}
          assert_response :success
          assert_not_nil(assigns(:post))
        end
      end
    end
    
    context "index action" do
      setup do
        @upload = Factory.create(:source_upload)
      end
      
      should "render" do
        get :index, {}, {:user_id => @user.id}
        assert_response :success
      end
      
      context "with search parameters" do
        should "render" do
          get :index, {:search => {:source_equals => @upload.source}}, {:user_id => @user.id}
          assert_response :success
        end
      end
    end
    
    context "show action" do
      setup do
        @upload = Factory.create(:jpg_upload)
      end
      
      should "render" do
        get :show, {:id => @upload.id}, {:user_id => @user.id}
        assert_response :success
      end
    end
    
    context "create action" do
      should "create a new upload" do
        assert_difference("Upload.count", 1) do
          post :create, {:upload => {:file => upload_jpeg("#{Rails.root}/test/files/test.jpg"), :tag_string => "aaa", :rating => "q", :source => "aaa"}}, {:user_id => @user.id}
        end
      end
    end
    
    context "update action" do
      setup do
        @upload = Factory.create(:jpg_upload)
      end
      
      should "process an unapproval" do
        post :update, {:id => @upload.id}, {:user_id => @user.id}
        @upload.reload
        assert_equal("completed", @upload.status)
      end
    end
  end
end
