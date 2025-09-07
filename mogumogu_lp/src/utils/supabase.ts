import { createClient } from '@supabase/supabase-js'

// 環境変数からSupabaseの設定を取得
// 環境変数が読み込まれない場合は、以下の値を直接設定してください
// const supabaseUrl = process.env.REACT_APP_SUPABASE_URL || 'https://qxipxelwahzjzlsgfnql.supabase.co'
// const supabaseAnonKey = process.env.REACT_APP_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4aXB4ZWx3YWh6anpsc2dmbnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MzA0MDYsImV4cCI6MjA2NTUwNjQwNn0._rogDYmZxRm-TAxDnu2i8e37DJmN-Nqbzk2JK9ubgzg'

// 一時的な解決策：直接値を設定
const supabaseUrl = 'https://qxipxelwahzjzlsgfnql.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4aXB4ZWx3YWh6anpsc2dmbnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MzA0MDYsImV4cCI6MjA2NTUwNjQwNn0._rogDYmZxRm-TAxDnu2i8e37DJmN-Nqbzk2JK9ubgzg'

// デバッグ用：環境変数の値を確認
console.log('Environment variables check:')
console.log('REACT_APP_SUPABASE_URL:', process.env.REACT_APP_SUPABASE_URL)
console.log('REACT_APP_SUPABASE_ANON_KEY:', process.env.REACT_APP_SUPABASE_ANON_KEY ? 'Set' : 'Not set')
console.log('supabaseUrl:', supabaseUrl)
console.log('supabaseAnonKey length:', supabaseAnonKey.length)

// 環境変数が設定されていない場合のエラーハンドリング
if (!supabaseUrl) {
  console.error('REACT_APP_SUPABASE_URL is not set in environment variables')
  throw new Error('Supabase URL is required. Please check your .env.local file.')
}

if (!supabaseAnonKey) {
  console.error('REACT_APP_SUPABASE_ANON_KEY is not set in environment variables')
  throw new Error('Supabase Anon Key is required. Please check your .env.local file.')
}

// Supabaseクライアントを作成
export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// ウェイティングリスト関連の型定義
export interface WaitingListEntry {
  id?: string
  email: string
  created_at?: string
  updated_at?: string
  is_notified?: boolean
  source?: string
}

// ウェイティングリストにメールアドレスを追加する関数
export const addToWaitingList = async (email: string, source: string = 'landing_page') => {
  try {
    const { data, error } = await supabase
      .from('waiting_list')
      .insert([
        {
          email,
          source
        }
      ])
      .select()

    if (error) {
      // 重複エラーの場合は特別な処理
      if (error.code === '23505') {
        throw new Error('このメールアドレスは既に登録されています')
      }
      throw error
    }

    return data
  } catch (error) {
    console.error('Error adding to waiting list:', error)
    throw error
  }
}

// ウェイティングリストの登録数を取得する関数
export const getWaitingListCount = async () => {
  try {
    const { count, error } = await supabase
      .from('waiting_list')
      .select('*', { count: 'exact', head: true })

    if (error) {
      throw error
    }

    return count || 0
  } catch (error) {
    console.error('Error getting waiting list count:', error)
    throw error
  }
} 