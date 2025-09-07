import React, { useState } from 'react';

const FAQSection: React.FC = () => {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  const faqs = [
    {
      question: '子どものプライバシーは守られますか？',
      answer: 'はい、お子さまのプライバシーを最優先に考えて設計しています。カメラで撮影した映像はすべてデバイス内で処理され、外部サーバーに送信されることはありません。また、個人を特定できる情報は収集せず、COPPA（児童オンラインプライバシー保護法）およびGDPRの要件を満たすよう開発を進めています。'
    },
    {
      question: 'どのテレビと連携できますか？',
      answer: 'スマートフォンから動画をキャスト可能なテレビと連携できます。Chromecast、Apple TV、Fire TV、Android TV搭載テレビなど、多くのスマートテレビに対応しています。'
    },
    {
      question: '複数の子どもを同時に見守れますか？',
      answer: 'はい、カメラの画角内であれば複数人同時に見守り可能です。この機能は無料プランでもご利用いただけます。お子さまが並んで座っている場合でも、それぞれの口の動きを個別に検知することができます。'
    },
    {
      question: 'データの取り扱いについて教えてください',
      answer: '映像データは一切保存されず、リアルタイムで解析後すぐに破棄されます。口の動きの検知結果のみを一時的に保持し、個人を特定できる情報は収集しません。また、13歳未満のお子さまの利用については、保護者の同意を必要とする設計になっています。'
    }
  ];

  const toggleFaq = (index: number) => {
    setOpenIndex(openIndex === index ? null : index);
  };

  return (
    <section id="faq" className="py-16 bg-white section-fade">
      <div className="container mx-auto px-4">
        <h2 className="text-2xl md:text-3xl font-bold text-center mb-12 text-gray-900">よくある質問</h2>
        
        <div className="max-w-3xl mx-auto">
          <div className="space-y-6">
            {faqs.map((faq, index) => (
              <div key={index} className="faq-item border border-gray-200 rounded-lg overflow-hidden">
                <button 
                  onClick={() => toggleFaq(index)}
                  className="faq-question w-full px-6 py-4 text-left font-medium flex justify-between items-center bg-gray-50 hover:bg-gray-100 transition-colors"
                >
                  <span>{faq.question}</span>
                  <i className={`ri-arrow-down-s-line faq-icon transition-transform ${openIndex === index ? 'rotate-180' : ''}`}></i>
                </button>
                <div className={`faq-answer px-6 py-4 bg-white ${openIndex === index ? '' : 'hidden'}`}>
                  <p className="text-gray-700">{faq.answer}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default FAQSection; 