const supabase = require('../config/db')

const AVATAR_BUCKET = 'avatars'
const REFERENCIA_BUCKET = 'referencias'

async function ensureBucket(bucketName, options = {}) {
  const { data, error } = await supabase.storage.listBuckets()

  if (error) {
    throw error
  }

  const bucket = Array.isArray(data)
    ? data.find((b) => b.name === bucketName)
    : null

  if (bucket) {
    if (!bucket.public) {
      const { error: updateError } = await supabase.storage.updateBucket(bucketName, {
        public: true,
        fileSizeLimit: options.fileSizeLimit || 10 * 1024 * 1024
      })

      if (updateError) {
        throw updateError
      }
    }

    return { created: false, bucket: bucketName }
  }

  const { data: createdBucket, error: createError } = await supabase.storage.createBucket(bucketName, {
    public: true,
    fileSizeLimit: options.fileSizeLimit || 10 * 1024 * 1024
  })

  if (createError) {
    throw createError
  }

  return { created: true, bucket: createdBucket?.name || bucketName }
}

async function ensureAvatarBucket() {
  return ensureBucket(AVATAR_BUCKET)
}

async function ensureReferenciaBucket() {
  return ensureBucket(REFERENCIA_BUCKET, { fileSizeLimit: 5 * 1024 * 1024 })
}

module.exports = {
  ensureAvatarBucket,
  ensureReferenciaBucket,
  AVATAR_BUCKET,
  REFERENCIA_BUCKET
}