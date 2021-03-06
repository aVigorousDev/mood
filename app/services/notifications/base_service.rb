module Notifications
  class BaseService
    class << self
      private

      def payload(notification)
        notification.data.merge(
          notification_id: notification.id,
          notification_nonce: notification.nonce,
        )
      end

      def send_it(notification)
        send_it!(notification)
      rescue Webpush::ExpiredSubscription => _error
        notification.subscription.discard!
      rescue StandardError => error
        # TODO: handle webpush errors
        # https://github.com/zaru/webpush/blob/c37b3d2f0550367a830da697f87d2d3f85bafddd/lib/webpush/request.rb#L158-L175
        Raven.capture_exception(error)
      end

      def send_it!(notification)
        webpush_send(notification).tap do |response|
          notification.update!(dispatched_at: Time.current) if response.kind_of? Net::HTTPSuccess
        end
      end

      def webpush_send(notification)
        subscription = notification.subscription.data.with_indifferent_access

        Webpush.payload_send(
          auth: subscription[:keys][:auth],
          endpoint: subscription[:endpoint],
          message: JSON.generate(payload(notification)),
          p256dh: subscription[:keys][:p256dh],
          vapid: {
            private_key: Env.vapid_private_key,
            public_key: Env.vapid_public_key,
            subject: Env.vapid_subject,
          },
        )
      end
    end
  end
end
