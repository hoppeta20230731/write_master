require 'rails_helper'

RSpec.describe Post, type: :model do
  before do
    @post = FactoryBot.build(:post)
  end

  describe '文章投稿機能' do
    context '文章投稿できるとき' do
      it '必要情報をすべて満たしていれば登録できる' do
        expect(@post).to be_valid
      end
      it 'word_countはnilでも登録できる' do
        @post.word_count = nil
        expect(@post).to be_valid
      end
    end
    context '文章投稿できないとき' do
      it 'titleが空では登録できない' do
        @post.title = ''
        @post.valid?
        expect(@post.errors.full_messages).to include "Title can't be blank"
      end
      it 'contentが空では登録できない' do
        @post.content = ''
        @post.valid?
        expect(@post.errors.full_messages).to include "Content can't be blank"
      end
      it 'word_countが英字では登録できない' do
        @post.word_count = 'a'
        @post.valid?
        expect(@post.errors.full_messages).to include 'Word count is not a number'
      end
      it 'userが紐づいていなければ登録できない' do
        @post.user = nil
        @post.valid?
        expect(@post.errors.full_messages).to include 'User must exist'
      end
    end
  end

  describe 'インスタンスメソッド' do
    describe '#draft?' do
      it 'draft_flagがfalseの場合、falseを返す' do
        @post.draft_flag = false
        expect(@post.draft?).to be false
      end
      
      it 'draft_flagがnilの場合、falseを返す' do
        @post.draft_flag = nil
        expect(@post.draft?).to be false
      end
    end
  end
end
