import { Metadata } from 'next';
import LegalPageLayout from '@/components/LegalPageLayout';

export const metadata: Metadata = {
  title: 'Privacy Policy - Cookstemma',
  description: 'Privacy Policy for Cookstemma recipe sharing platform',
};

export default function PrivacyPolicyPage() {
  return (
    <LegalPageLayout title="Privacy Policy" lastUpdated="January 14, 2025">
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">1. Introduction</h2>
        <p className="text-gray-700 mb-4">
          Cookstemma (&quot;we,&quot; &quot;our,&quot; or &quot;us&quot;) respects your privacy and is committed to
          protecting your personal data. This Privacy Policy explains how we collect, use,
          disclose, and safeguard your information when you use our mobile application and
          website (the &quot;Service&quot;).
        </p>
        <p className="text-gray-700">
          Please read this Privacy Policy carefully. By using the Service, you consent to the
          practices described in this policy.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">2. Information We Collect</h2>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">2.1 Information You Provide</h3>
        <p className="text-gray-700 mb-4">When you create an account and use our Service, we collect:</p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li><strong>Account Information:</strong> Email address and name (from Google or Apple sign-in)</li>
          <li><strong>Profile Information:</strong> Username, profile photo, bio, birth date, gender</li>
          <li><strong>Preferences:</strong> Preferred cuisine style, measurement units, dietary preferences</li>
          <li><strong>Social Links:</strong> YouTube URL, Instagram handle (optional)</li>
          <li><strong>Content:</strong> Recipes, cooking logs, photos, comments you create</li>
        </ul>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">2.2 Information Collected Automatically</h3>
        <p className="text-gray-700 mb-4">When you use the Service, we automatically collect:</p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li><strong>Device Information:</strong> Device type (iOS/Android), operating system version</li>
          <li><strong>Usage Data:</strong> Features used, recipes viewed, searches performed</li>
          <li><strong>Analytics:</strong> App interactions, session duration, crash reports</li>
          <li><strong>Push Notification Token:</strong> For sending notifications (with your permission)</li>
        </ul>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">2.3 Information from Third Parties</h3>
        <p className="text-gray-700">
          When you sign in with Google or Apple, we receive your email address, name, and
          profile picture (if available) from these providers.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">3. How We Use Your Information</h2>
        <p className="text-gray-700 mb-4">We use your information to:</p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li>Provide, maintain, and improve the Service</li>
          <li>Create and manage your account</li>
          <li>Enable you to create, share, and discover recipes</li>
          <li>Send push notifications about activity on your content (with permission)</li>
          <li>Respond to your comments, questions, and requests</li>
          <li>Monitor and analyze usage patterns to improve user experience</li>
          <li>Detect, prevent, and address technical issues and security threats</li>
          <li>Comply with legal obligations</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">4. How We Share Your Information</h2>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">4.1 Public Information</h3>
        <p className="text-gray-700 mb-4">
          The following information is publicly visible to other users:
        </p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li>Username and profile photo</li>
          <li>Bio and social media links</li>
          <li>Recipes and cooking logs you create</li>
          <li>Comments and interactions</li>
        </ul>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">4.2 Service Providers</h3>
        <p className="text-gray-700 mb-4">We share data with third-party service providers:</p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li><strong>Firebase (Google):</strong> Authentication, crash reporting, push notifications</li>
          <li><strong>Cloud Hosting:</strong> Data storage and processing</li>
          <li><strong>Analytics Providers:</strong> Usage analysis and app performance</li>
        </ul>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">4.3 Legal Requirements</h3>
        <p className="text-gray-700">
          We may disclose your information if required by law, regulation, legal process, or
          governmental request, or to protect the rights, property, or safety of our users or others.
        </p>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">4.4 We Do Not Sell Your Data</h3>
        <p className="text-gray-700">
          We do not sell, rent, or trade your personal information to third parties for their
          marketing purposes.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">5. Data Retention</h2>
        <p className="text-gray-700 mb-4">We retain your information as follows:</p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li><strong>Account Data:</strong> Until you delete your account</li>
          <li><strong>Content:</strong> Until you delete it or your account is deleted</li>
          <li><strong>Analytics Data:</strong> Aggregated data may be retained indefinitely</li>
          <li><strong>After Account Deletion:</strong> 30-day grace period, then permanent deletion</li>
        </ul>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">6. Data Security</h2>
        <p className="text-gray-700 mb-4">
          We implement appropriate technical and organizational measures to protect your data:
        </p>
        <ul className="list-disc list-inside text-gray-700 space-y-2">
          <li>Encryption in transit (HTTPS/TLS)</li>
          <li>Secure storage of authentication tokens</li>
          <li>Regular security assessments</li>
          <li>Access controls and authentication</li>
        </ul>
        <p className="text-gray-700 mt-4">
          However, no method of transmission over the Internet is 100% secure. While we strive
          to protect your information, we cannot guarantee absolute security.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">7. Your Rights and Choices</h2>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">7.1 Access and Update</h3>
        <p className="text-gray-700 mb-4">
          You can access and update your profile information at any time through the app settings.
        </p>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">7.2 Delete Your Account</h3>
        <p className="text-gray-700 mb-4">
          You can delete your account through the app settings. After requesting deletion,
          your account will be permanently deleted after a 30-day grace period during which
          you can recover your account.
        </p>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">7.3 Push Notifications</h3>
        <p className="text-gray-700 mb-4">
          You can disable push notifications through your device settings at any time.
        </p>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">7.4 Marketing Communications</h3>
        <p className="text-gray-700">
          You can opt out of marketing communications through the app settings or by following
          the unsubscribe instructions in any marketing email.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">8. Children&apos;s Privacy</h2>
        <p className="text-gray-700 mb-4">
          Our Service is not intended for children under 13. We do not knowingly collect
          personal information from children under 13. If you are a parent or guardian and
          believe your child has provided us with personal information, please contact us.
        </p>
        <p className="text-gray-700">
          If we discover that we have collected personal information from a child under 13,
          we will delete that information as quickly as possible.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">9. International Data Transfers</h2>
        <p className="text-gray-700">
          Your information may be transferred to and processed in countries other than your
          country of residence. These countries may have different data protection laws.
          By using the Service, you consent to the transfer of your information to these
          countries.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">10. Third-Party Links</h2>
        <p className="text-gray-700">
          Our Service may contain links to third-party websites or services. We are not
          responsible for the privacy practices of these third parties. We encourage you to
          read the privacy policies of any third-party services you visit.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">11. Changes to This Policy</h2>
        <p className="text-gray-700">
          We may update this Privacy Policy from time to time. We will notify you of any
          material changes by posting the new Privacy Policy on the Service and updating
          the &quot;Last updated&quot; date. Your continued use of the Service after such changes
          constitutes your acceptance of the updated policy.
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">12. Contact Us</h2>
        <p className="text-gray-700 mb-4">
          If you have any questions about this Privacy Policy or our data practices, please
          contact us at:
        </p>
        <p className="text-gray-700">
          <strong>Email:</strong> privacy@cookstemma.com
        </p>
      </section>

      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">13. Additional Information for Specific Regions</h2>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">For Users in the European Economic Area (EEA)</h3>
        <p className="text-gray-700 mb-4">
          If you are in the EEA, you have certain rights under the General Data Protection
          Regulation (GDPR), including:
        </p>
        <ul className="list-disc list-inside text-gray-700 mb-4 space-y-2">
          <li>Right to access your personal data</li>
          <li>Right to rectification of inaccurate data</li>
          <li>Right to erasure (&quot;right to be forgotten&quot;)</li>
          <li>Right to restrict processing</li>
          <li>Right to data portability</li>
          <li>Right to object to processing</li>
        </ul>

        <h3 className="text-lg font-medium text-gray-800 mt-6 mb-3">For Users in California</h3>
        <p className="text-gray-700">
          California residents have additional rights under the California Consumer Privacy
          Act (CCPA), including the right to know what personal information is collected,
          the right to delete personal information, and the right to opt-out of the sale of
          personal information. We do not sell personal information.
        </p>
      </section>

      {/* Data Collection Summary Table */}
      <section className="mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">Data Collection Summary</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full border border-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left border-b">Data Type</th>
                <th className="px-4 py-2 text-left border-b">Collected</th>
                <th className="px-4 py-2 text-left border-b">Shared</th>
                <th className="px-4 py-2 text-left border-b">Purpose</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td className="px-4 py-2 border-b">Name</td>
                <td className="px-4 py-2 border-b">Yes</td>
                <td className="px-4 py-2 border-b">Public (username)</td>
                <td className="px-4 py-2 border-b">Account identification</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="px-4 py-2 border-b">Email</td>
                <td className="px-4 py-2 border-b">Yes</td>
                <td className="px-4 py-2 border-b">No</td>
                <td className="px-4 py-2 border-b">Account, notifications</td>
              </tr>
              <tr>
                <td className="px-4 py-2 border-b">Birth Date</td>
                <td className="px-4 py-2 border-b">Yes</td>
                <td className="px-4 py-2 border-b">No</td>
                <td className="px-4 py-2 border-b">Age verification</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="px-4 py-2 border-b">Photos</td>
                <td className="px-4 py-2 border-b">Yes</td>
                <td className="px-4 py-2 border-b">Public (recipes/logs)</td>
                <td className="px-4 py-2 border-b">App functionality</td>
              </tr>
              <tr>
                <td className="px-4 py-2 border-b">Device Info</td>
                <td className="px-4 py-2 border-b">Yes</td>
                <td className="px-4 py-2 border-b">Firebase</td>
                <td className="px-4 py-2 border-b">Push notifications</td>
              </tr>
              <tr className="bg-gray-50">
                <td className="px-4 py-2 border-b">Usage Data</td>
                <td className="px-4 py-2 border-b">Yes</td>
                <td className="px-4 py-2 border-b">No</td>
                <td className="px-4 py-2 border-b">Analytics, improvement</td>
              </tr>
              <tr>
                <td className="px-4 py-2">Crash Reports</td>
                <td className="px-4 py-2">Yes</td>
                <td className="px-4 py-2">Firebase</td>
                <td className="px-4 py-2">Bug fixing</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </LegalPageLayout>
  );
}
