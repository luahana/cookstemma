import { Metadata } from 'next';
import LegalPageLayout from '@/components/LegalPageLayout';

export const metadata: Metadata = {
  title: 'Terms of Service - Cookstemma',
  description: 'Terms of Service for Cookstemma recipe sharing platform',
};

export default function TermsOfServicePage() {
  return (
    <LegalPageLayout title="Terms of Service" lastUpdated="January 14, 2025">
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">1. Acceptance of Terms</h2>
        <p className="text-gray-700 mb-4">
          Welcome to Cookstemma. By accessing or using our mobile application and website
          (collectively, the &quot;Service&quot;), you agree to be bound by these Terms of Service
          (&quot;Terms&quot;). If you do not agree to these Terms, please do not use the Service.
        </p>
        <p className="text-gray-700">
          We reserve the right to modify these Terms at any time. We will notify you of any
          material changes by posting the new Terms on the Service and updating the &quot;Last
          updated&quot; date. Your continued use of the Service after such changes constitutes
          your acceptance of the new Terms.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">2. Eligibility</h2>
        <p className="text-gray-700 mb-4">
          You must be at least 13 years old to use this Service. By using the Service, you
          represent and warrant that you are at least 13 years of age. If you are under 18,
          you represent that you have your parent or guardian&apos;s permission to use the Service.
        </p>
        <p className="text-gray-700">
          If we learn that we have collected personal information from a child under 13, we
          will delete that information as quickly as possible. If you believe that a child
          under 13 may have provided us personal information, please contact us.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">3. Account Registration</h2>
        <p className="text-gray-700 mb-4">
          To access certain features of the Service, you must create an account using Google
          Sign-In or Sign in with Apple. You agree to:
        </p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li>Provide accurate and complete information</li>
          <li>Maintain the security of your account credentials</li>
          <li>Promptly update any information to keep it accurate</li>
          <li>Accept responsibility for all activities under your account</li>
          <li>Notify us immediately of any unauthorized use</li>
        </ul>
        <p className="text-gray-700">
          We reserve the right to suspend or terminate accounts that violate these Terms or
          for any other reason at our sole discretion.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">4. User Content</h2>
        <p className="text-gray-700 mb-4">
          Our Service allows you to post, share, and store content including recipes, photos,
          cooking logs, and comments (&quot;User Content&quot;). You retain ownership of your User
          Content, but by posting it, you grant us a worldwide, non-exclusive, royalty-free
          license to use, reproduce, modify, distribute, and display your User Content in
          connection with operating and providing the Service.
        </p>
        <p className="text-gray-700 mb-4">You represent and warrant that:</p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li>You own or have the right to post your User Content</li>
          <li>Your User Content does not infringe any third-party rights</li>
          <li>Your User Content complies with these Terms and all applicable laws</li>
        </ul>
        <p className="text-gray-700">
          We reserve the right to remove any User Content that violates these Terms or that
          we find objectionable for any reason.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">5. Prohibited Conduct</h2>
        <p className="text-gray-700 mb-4">You agree not to:</p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li>Use the Service for any illegal purpose</li>
          <li>Post content that is harmful, threatening, abusive, or harassing</li>
          <li>Impersonate any person or entity</li>
          <li>Post spam, advertisements, or promotional material without permission</li>
          <li>Interfere with or disrupt the Service or servers</li>
          <li>Attempt to gain unauthorized access to any part of the Service</li>
          <li>Use automated means to access the Service without permission</li>
          <li>Collect or harvest user information without consent</li>
          <li>Post content that infringes intellectual property rights</li>
          <li>Post recipes or content that promotes dangerous activities</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">6. Recipe Variations</h2>
        <p className="text-gray-700 mb-4">
          Our Service allows users to create variations of existing recipes. When creating a
          variation:
        </p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li>The original recipe creator retains credit for the original recipe</li>
          <li>Your variation will be linked to the original recipe</li>
          <li>You must make meaningful changes and document what you changed</li>
          <li>You grant other users the same right to create variations of your recipes</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">7. Intellectual Property</h2>
        <p className="text-gray-700 mb-4">
          The Service and its original content (excluding User Content), features, and
          functionality are owned by Cookstemma and are protected by international
          copyright, trademark, and other intellectual property laws.
        </p>
        <p className="text-gray-700">
          Our trademarks and trade dress may not be used in connection with any product or
          service without our prior written consent.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">8. Third-Party Services</h2>
        <p className="text-gray-700">
          Our Service uses third-party services including Google Sign-In, Sign in with Apple,
          and Firebase. Your use of these services is subject to their respective terms of
          service and privacy policies. We are not responsible for the practices of these
          third-party services.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">9. Disclaimers</h2>
        <p className="text-gray-700 mb-4">
          THE SERVICE IS PROVIDED &quot;AS IS&quot; AND &quot;AS AVAILABLE&quot; WITHOUT WARRANTIES OF ANY
          KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED,
          SECURE, OR ERROR-FREE.
        </p>
        <p className="text-gray-700 mb-4">
          Recipe content is provided by users and we do not guarantee the accuracy, safety,
          or suitability of any recipe. Users are responsible for:
        </p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li>Verifying ingredients for allergens and dietary restrictions</li>
          <li>Following safe food handling and cooking practices</li>
          <li>Adjusting recipes as needed for their specific circumstances</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">10. Limitation of Liability</h2>
        <p className="text-gray-700">
          TO THE MAXIMUM EXTENT PERMITTED BY LAW, COOKSTEMMA SHALL NOT BE LIABLE FOR ANY
          INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT
          NOT LIMITED TO LOSS OF PROFITS, DATA, OR USE, ARISING OUT OF OR IN CONNECTION WITH
          YOUR USE OF THE SERVICE.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">11. Indemnification</h2>
        <p className="text-gray-700">
          You agree to indemnify and hold harmless Cookstemma and its officers, directors,
          employees, and agents from any claims, damages, losses, or expenses arising out of
          your use of the Service, your User Content, or your violation of these Terms.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">12. Termination</h2>
        <p className="text-gray-700 mb-4">
          You may terminate your account at any time by using the account deletion feature in
          the app settings. Upon requesting deletion, your account will be scheduled for
          permanent deletion after a 30-day grace period.
        </p>
        <p className="text-gray-700">
          We may terminate or suspend your account immediately, without prior notice, for
          conduct that we believe violates these Terms or is harmful to other users, us, or
          third parties, or for any other reason at our sole discretion.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">13. Governing Law</h2>
        <p className="text-gray-700">
          These Terms shall be governed by and construed in accordance with the laws of the
          Republic of Korea, without regard to its conflict of law provisions. Any disputes
          arising from these Terms shall be resolved in the courts of Seoul, Republic of Korea.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">14. Changes to Terms</h2>
        <p className="text-gray-700">
          We reserve the right to modify these Terms at any time. If we make material changes,
          we will notify you through the Service or by other means. Your continued use of the
          Service after such notification constitutes your acceptance of the modified Terms.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">15. Contact Us</h2>
        <p className="text-gray-700">
          If you have any questions about these Terms, please contact us at:
        </p>
        <p className="text-gray-700 mt-2">
          <strong>Email:</strong> support@cookstemma.com
        </p>
      </section>
    </LegalPageLayout>
  );
}
