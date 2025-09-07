import React, { useState, useEffect } from 'react';
import { addToWaitingList, getWaitingListCount } from '../utils/supabase';

const WaitingListSection: React.FC = () => {
  const [email, setEmail] = useState('');
  const [isSubmitted, setIsSubmitted] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [waitingListCount, setWaitingListCount] = useState<number | null>(null);

  // コンポーネントマウント時にウェイティングリストの登録数を取得
  useEffect(() => {
    const fetchWaitingListCount = async () => {
      try {
        const count = await getWaitingListCount();
        setWaitingListCount(count);
      } catch (error) {
        console.error('Failed to fetch waiting list count:', error);
      }
    };

    fetchWaitingListCount();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;

    setIsLoading(true);
    setError(null);
    
    try {
      await addToWaitingList(email, 'landing_page');
      setIsSubmitted(true);
      setEmail('');
      
      // 登録数を更新
      const newCount = await getWaitingListCount();
      setWaitingListCount(newCount);
    } catch (error) {
      console.error('Error submitting to waiting list:', error);
      if (error instanceof Error) {
        setError(error.message);
      } else {
        setError('登録に失敗しました。しばらく時間をおいて再度お試しください。');
      }
    } finally {
      setIsLoading(false);
    }
  };

  const resetForm = () => {
    setIsSubmitted(false);
    setError(null);
    setEmail('');
  };

  return (
    <section id="waiting-list" className="py-16 bg-primary/5 section-fade">
      <div className="container mx-auto px-4">
        <div className="max-w-2xl mx-auto text-center">
          <h2 className="text-2xl md:text-3xl font-bold mb-4 text-gray-900">
            リリース通知を受け取る
          </h2>
          <p className="text-gray-600 mb-8">
            もぐもぐウォッチのリリース情報をいち早くお届けします。
          </p>

          {/* 登録数表示 */}
          {waitingListCount !== null && (
            <div className="mb-6">
              <p className="text-sm text-gray-500">
                現在 <span className="font-semibold text-primary">{waitingListCount}</span> 名の方が登録済み
              </p>
            </div>
          )}

          {!isSubmitted ? (
            <>
              <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-4 max-w-md mx-auto">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="メールアドレスを入力"
                  className="flex-1 px-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                  required
                  disabled={isLoading}
                />
                <button
                  type="submit"
                  disabled={isLoading || !email}
                  className="px-6 py-3 bg-primary text-white rounded-lg font-medium hover:bg-opacity-90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed whitespace-nowrap"
                >
                  {isLoading ? (
                    <span className="flex items-center">
                      <i className="ri-loader-4-line animate-spin mr-2"></i>
                      登録中...
                    </span>
                  ) : (
                    '通知を受け取る'
                  )}
                </button>
              </form>

              {/* エラーメッセージ */}
              {error && (
                <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg">
                  <p className="text-red-600 text-sm">{error}</p>
                  {error.includes('既に登録') && (
                    <p className="text-red-500 text-xs mt-1">
                      別のメールアドレスをお試しください
                    </p>
                  )}
                </div>
              )}
            </>
          ) : (
            <div className="bg-white p-6 rounded-lg shadow-sm border border-primary/20">
              <div className="flex items-center justify-center mb-4">
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
                  <i className="ri-check-line text-primary text-xl"></i>
                </div>
              </div>
              <h3 className="text-lg font-semibold mb-2 text-gray-900">登録完了！</h3>
              <p className="text-gray-600 mb-4">
                ありがとうございます。リリース情報をお送りいたします。
              </p>
              <button
                onClick={resetForm}
                className="text-primary hover:text-primary/80 text-sm font-medium transition-colors"
              >
                別のメールアドレスを登録する
              </button>
            </div>
          )}
        </div>
      </div>
    </section>
  );
};

export default WaitingListSection; 