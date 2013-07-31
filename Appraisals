['~> 3.1.12', '~> 3.2.14', '~> 4.0.0'].each do |activerecord_version|
  appraise "activerecord_#{activerecord_version.slice(/\d+\.\d+/)}" do
    gem 'activerecord', activerecord_version
  end
end
