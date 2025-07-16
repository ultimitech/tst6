require "test_helper"

class TranslationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @translation = translations(:one)
  end

  test "should get index" do
    get translations_url
    assert_response :success
  end

  test "should get new" do
    get new_translation_url
    assert_response :success
  end

  test "should create translation" do
    assert_difference("Translation.count") do
      post translations_url, params: { translation: { blkc: @translation.blkc, descrip: @translation.descrip, lan: @translation.lan, li: @translation.li, message_id: @translation.message_id, pubdate: @translation.pubdate, senc: @translation.senc, subc: @translation.subc, tran_title: @translation.tran_title, version: @translation.version, xcrip: @translation.xcrip } }
    end

    assert_redirected_to translation_url(Translation.last)
  end

  test "should show translation" do
    get translation_url(@translation)
    assert_response :success
  end

  test "should get edit" do
    get edit_translation_url(@translation)
    assert_response :success
  end

  test "should update translation" do
    patch translation_url(@translation), params: { translation: { blkc: @translation.blkc, descrip: @translation.descrip, lan: @translation.lan, li: @translation.li, message_id: @translation.message_id, pubdate: @translation.pubdate, senc: @translation.senc, subc: @translation.subc, tran_title: @translation.tran_title, version: @translation.version, xcrip: @translation.xcrip } }
    assert_redirected_to translation_url(@translation)
  end

  test "should destroy translation" do
    assert_difference("Translation.count", -1) do
      delete translation_url(@translation)
    end

    assert_redirected_to translations_url
  end
end
