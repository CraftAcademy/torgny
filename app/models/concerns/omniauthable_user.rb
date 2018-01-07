module OmniauthableUser
  extend ActiveSupport::Concern

  # TODO: Refactor the following methods to one. Lot of duplication here...
  included do
    # Add SecureRandom.hex to user's email to avaoid confilict between
    # providers. If one user uses the same email for Facebook and Google,
    # prepending this string will not cause "email has already been taken" error.
    def self.find_or_create_from_facebook_omniauth(auth)
      user = where(provider: auth.provider, uid: auth.uid).first_or_create
      unless auth.info.image.nil?
        user.remote_avatar_url = auth.info.image.gsub('http://', 'https://') + '?type=large'
      end
      user.assign_attributes(
          email: auth.info.email,
          password: Devise.friendly_token[0, 20],
          username: auth.info.name
      )
      user.save(validate: false) # hack to allow duplicate emails
      user
    end

    def self.find_or_create_from_twitter_omniauth(auth)
      user = where(provider: auth.provider, uid: auth.uid).first_or_create
      unless auth.info.image.nil?
        user.remote_avatar_url = auth.info.image.gsub('http://', 'https://').gsub('_normal', '')
      end
      user.assign_attributes(
          username: auth.info.name,
          password: Devise.friendly_token[0, 20],
          email: auth.info.email # Note that Twitter does not provide email if you don't request that in your app settings
      )
      user.save(validate: false) # hack to allow duplicate emails
      user
    end

    def self.find_or_create_from_google_omniauth(auth)
      user = where(provider: auth.provider, uid: auth.uid).first_or_create
      user.remote_avatar_url = auth.info.image
      user.assign_attributes(
          username: auth.info.name,
          email: auth.info.email,
          password: Devise.friendly_token[0, 20]
      )
      user.save(validate: false) # hack to allow duplicate emails
      user
    end

    def self.new_with_session(params, session)
      if session["devise.user_attributes"]
        new(session["devise.user_attributes"]) do |user|
          user.attributes = params
          user.valid?
        end
      else
        super
      end
    end

  end


  def password_required?
    super && self.provider.blank?
  end

  def email_required?
    super && self.provider.blank?
  end

end


