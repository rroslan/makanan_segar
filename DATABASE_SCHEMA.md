# Database Schema Documentation

## Entity Relationship Diagram (ERD)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            MakananSegar Database Schema                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐    1:N    ┌──────────────────────┐    1:N    ┌──────────────────────┐
│       USERS          │◄──────────┤      PRODUCTS        │◄──────────┤    CHAT_MESSAGES     │
├──────────────────────┤           ├──────────────────────┤           ├──────────────────────┤
│ PK id (bigserial)    │           │ PK id (bigserial)    │           │ PK id (bigserial)    │
│    name (varchar)    │           │    name (varchar)    │           │    content (text)    │
│    email (varchar) U │           │    description (text)│           │    sender_name       │
│    is_admin (bool)   │           │    category (varchar)│           │    sender_email      │
│    is_vendor (bool)  │           │    price (decimal)   │           │ FK product_id        │
│    confirmed_at      │           │ FK user_id           │           │ FK user_id (nullable)│
│    address (text)    │           │    expires_at        │           │    is_vendor_reply   │
│    phone (varchar)   │           │    is_active (bool)  │           │    inserted_at       │
│    business_name     │           │    image (varchar)   │           │    updated_at        │
│    business_desc     │           │    inserted_at       │           └──────────────────────┘
│    business_type     │           │    updated_at        │                        │
│    business_hours    │           └──────────────────────┘                        │
│    website           │                      │                                     │
│    profile_image     │                      │ 1:1                                │ 1:N
│    inserted_at       │                      ▼                                     ▼
│    updated_at        │           ┌──────────────────────┐           ┌──────────────────────┐
└──────────────────────┘           │    CONVERSATIONS     │           │    MESSAGE_READS     │
           │                       ├──────────────────────┤           ├──────────────────────┤
           │ 1:N                   │ PK id (bigserial)    │           │ PK id (bigserial)    │
           │                       │ FK product_id (U)    │           │ FK message_id        │
           │                       │    status (varchar)  │           │ FK user_id           │
           └───────────────────────┤ FK resolved_by_uid   │           │    read_at           │
                                   │    resolved_at       │           │    inserted_at       │
                                   │    inserted_at       │           │    updated_at        │
                                   │    updated_at        │           └──────────────────────┘
                                   └──────────────────────┘

LEGEND:
PK = Primary Key
FK = Foreign Key
U  = Unique Constraint
1:N = One-to-Many Relationship
1:1 = One-to-One Relationship
```

## Table Definitions

### 1. USERS Table
**Purpose**: Store user accounts for customers, vendors, and administrators

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigserial | PRIMARY KEY | Auto-incrementing user ID |
| name | varchar(255) | | User's full name |
| email | varchar(255) | NOT NULL, UNIQUE | Email address for login |
| is_admin | boolean | DEFAULT false | Admin privileges flag |
| is_vendor | boolean | DEFAULT false | Vendor privileges flag |
| confirmed_at | timestamp | | Email confirmation timestamp |
| address | text | | Physical address |
| phone | varchar(50) | | Contact phone number |
| business_name | varchar(255) | | Vendor business name |
| business_description | text | | Vendor business description |
| business_type | varchar(100) | | Business category (fish/vegetables/fruits) |
| business_hours | varchar(255) | | Operating hours |
| website | varchar(255) | | Business website URL |
| profile_image | varchar(500) | | Profile/business image URL |
| inserted_at | timestamp | NOT NULL | Record creation time |
| updated_at | timestamp | NOT NULL | Last update time |

**Indexes:**
- Primary key on `id`
- Unique index on `email`

### 2. PRODUCTS Table
**Purpose**: Store product listings from vendors

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigserial | PRIMARY KEY | Auto-incrementing product ID |
| name | varchar(255) | NOT NULL | Product name |
| description | text | | Product description |
| category | varchar(100) | NOT NULL | Product category (fish/vegetables/fruits) |
| price | decimal(10,2) | NOT NULL | Product price in RM |
| user_id | bigint | FK → users(id) CASCADE | Vendor who owns this product |
| expires_at | timestamp | | Product expiry date |
| is_active | boolean | DEFAULT true | Whether product is available |
| image | varchar(500) | | Product image URL |
| inserted_at | timestamp | NOT NULL | Record creation time |
| updated_at | timestamp | NOT NULL | Last update time |

**Indexes:**
- Primary key on `id`
- Foreign key index on `user_id`
- Composite index on `(category, is_active)`

### 3. CHAT_MESSAGES Table
**Purpose**: Store chat messages between customers and vendors

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigserial | PRIMARY KEY | Auto-incrementing message ID |
| content | text | NOT NULL | Message content |
| sender_name | varchar(255) | | Guest customer name (if not logged in) |
| sender_email | varchar(255) | | Guest customer email (if not logged in) |
| product_id | bigint | FK → products(id) CASCADE | Product being discussed |
| user_id | bigint | FK → users(id) SET NULL | Authenticated user who sent message |
| is_vendor_reply | boolean | DEFAULT false | True if message is from vendor |
| inserted_at | timestamp | NOT NULL | Message timestamp |
| updated_at | timestamp | NOT NULL | Last update time |

**Indexes:**
- Primary key on `id`
- Index on `product_id`
- Index on `user_id`
- Composite index on `(product_id, inserted_at)` for chronological ordering

### 4. CONVERSATIONS Table
**Purpose**: Track conversation status between customers and vendors per product

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigserial | PRIMARY KEY | Auto-incrementing conversation ID |
| product_id | bigint | FK → products(id) CASCADE, UNIQUE | Product being discussed |
| status | varchar(50) | DEFAULT 'open', CHECK (open/resolved) | Conversation status |
| resolved_at | timestamp | | When conversation was resolved |
| resolved_by_user_id | bigint | FK → users(id) SET NULL | Vendor who resolved conversation |
| inserted_at | timestamp | NOT NULL | Record creation time |
| updated_at | timestamp | NOT NULL | Last update time |

**Constraints:**
- Check constraint: `status IN ('open', 'resolved')`
- Business logic constraint: If status = 'resolved', then `resolved_at` and `resolved_by_user_id` must be NOT NULL
- Business logic constraint: If status = 'open', then `resolved_at` and `resolved_by_user_id` must be NULL

**Indexes:**
- Primary key on `id`
- Unique index on `product_id`
- Index on `status`
- Composite index on `(product_id, status)`

### 5. MESSAGE_READS Table
**Purpose**: Track which messages have been read by which users (for persistent notifications)

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigserial | PRIMARY KEY | Auto-incrementing read record ID |
| message_id | bigint | FK → chat_messages(id) CASCADE | Message that was read |
| user_id | bigint | FK → users(id) CASCADE | User who read the message |
| read_at | timestamp | NOT NULL | When message was read |
| inserted_at | timestamp | NOT NULL | Record creation time |
| updated_at | timestamp | NOT NULL | Last update time |

**Constraints:**
- Unique constraint on `(message_id, user_id)` - prevents duplicate read records

**Indexes:**
- Primary key on `id`
- Index on `message_id`
- Index on `user_id`
- Unique composite index on `(message_id, user_id)`

## Relationships

### User Relationships
- **Users → Products**: One-to-Many (vendors can have multiple products)
- **Users → Chat Messages**: One-to-Many (users can send multiple messages)
- **Users → Conversations**: One-to-Many via `resolved_by_user_id` (vendors can resolve multiple conversations)
- **Users → Message Reads**: One-to-Many (users can read multiple messages)

### Product Relationships
- **Products → Chat Messages**: One-to-Many (each product can have multiple chat messages)
- **Products → Conversations**: One-to-One (each product has at most one conversation record)

### Message Relationships
- **Chat Messages → Message Reads**: One-to-Many (each message can be read by multiple users)

## Data Flow Examples

### 1. Customer Inquiry Flow
```sql
-- 1. Customer sends message about a product
INSERT INTO chat_messages (content, product_id, sender_name, sender_email, is_vendor_reply)
VALUES ('Is this fish fresh?', 1, 'John Customer', 'john@email.com', false);

-- 2. Conversation is auto-created if not exists
INSERT INTO conversations (product_id, status)
VALUES (1, 'open')
ON CONFLICT (product_id) DO NOTHING;

-- 3. Vendor sees notification (query for unread messages in open conversations)
SELECT p.id, COUNT(cm.id) as unread_count
FROM products p
LEFT JOIN chat_messages cm ON p.id = cm.product_id
LEFT JOIN conversations c ON p.id = c.product_id
LEFT JOIN message_reads mr ON cm.id = mr.message_id AND mr.user_id = $vendor_id
WHERE p.user_id = $vendor_id 
  AND cm.is_vendor_reply = false 
  AND (c.status = 'open' OR c.status IS NULL)
  AND mr.id IS NULL
GROUP BY p.id;
```

### 2. Vendor Reply Flow
```sql
-- 1. Vendor replies to customer
INSERT INTO chat_messages (content, product_id, user_id, is_vendor_reply)
VALUES ('Yes, caught this morning!', 1, $vendor_id, true);

-- 2. No notification created (vendor replies don't generate notifications)
```

### 3. Conversation Resolution Flow
```sql
-- 1. Vendor marks conversation as resolved
UPDATE conversations 
SET status = 'resolved', 
    resolved_at = NOW(), 
    resolved_by_user_id = $vendor_id
WHERE product_id = 1;

-- 2. Notifications automatically hidden (query filters out resolved conversations)
```

### 4. Read Tracking Flow
```sql
-- 1. Mark messages as read when vendor opens chat
INSERT INTO message_reads (message_id, user_id, read_at)
SELECT cm.id, $vendor_id, NOW()
FROM chat_messages cm
LEFT JOIN message_reads mr ON cm.id = mr.message_id AND mr.user_id = $vendor_id
WHERE cm.product_id = $product_id 
  AND cm.is_vendor_reply = false 
  AND mr.id IS NULL;

-- 2. Notifications updated to exclude read messages
```

## Query Performance Considerations

### Optimized Notification Query
```sql
-- Get unread message counts for vendor (only open conversations)
SELECT cm.product_id, COUNT(*) as unread_count
FROM chat_messages cm
JOIN products p ON cm.product_id = p.id
LEFT JOIN conversations c ON c.product_id = p.id
LEFT JOIN message_reads mr ON mr.message_id = cm.id AND mr.user_id = $vendor_id
WHERE p.user_id = $vendor_id 
  AND cm.is_vendor_reply = false
  AND (c.status = 'open' OR c.status IS NULL)
  AND mr.id IS NULL
GROUP BY cm.product_id;
```

**Performance Notes:**
- Uses indexes on `products(user_id)`, `chat_messages(product_id)`, `conversations(product_id, status)`
- Left joins ensure products without messages/conversations are still included
- Filtering on indexed columns for optimal performance

### Message History Query
```sql
-- Get chronological message history for a product
SELECT cm.*, u.name as sender_name
FROM chat_messages cm
LEFT JOIN users u ON cm.user_id = u.id
WHERE cm.product_id = $product_id
ORDER BY cm.inserted_at ASC;
```

**Performance Notes:**
- Uses composite index on `(product_id, inserted_at)` for optimal ordering
- Left join with users for sender information

## Migration History

### Initial Schema (Migration 1)
- Created `users` table with basic authentication fields

### Product Management (Migration 2)
- Created `products` table
- Added foreign key relationship to `users`

### Chat System (Migration 3)
- Created `chat_messages` table
- Added support for guest customers and vendor replies

### Conversation Management (Migration 4)
- Created `conversations` table
- Added status tracking and resolution workflow

### Read Tracking (Migration 5)
- Created `message_reads` table
- Added persistent notification system

## Data Integrity Rules

### Business Logic Constraints
1. **Vendor Ownership**: Only product owners can reply as vendors
2. **Conversation Status**: Resolved conversations must have resolution metadata
3. **Message Threading**: All messages must be associated with a product
4. **Read Tracking**: Users can only mark messages as read once
5. **User Roles**: Admin and vendor flags are mutually exclusive with customer role

### Referential Integrity
- **CASCADE DELETE**: When products are deleted, all related messages and conversations are deleted
- **SET NULL**: When users are deleted, their messages remain but user reference is nullified
- **RESTRICT DELETE**: Cannot delete users who have resolved conversations (maintains audit trail)

## Backup and Recovery Considerations

### Critical Data Tables
1. **users** - Contains all account information
2. **products** - Contains all product listings
3. **chat_messages** - Contains all customer communication
4. **conversations** - Contains conversation status (for business metrics)

### Recovery Priority
1. **High**: users, products (core business data)
2. **Medium**: chat_messages, conversations (customer service)
3. **Low**: message_reads (can be rebuilt from user behavior)

### Backup Strategy
- **Daily**: Full database backup
- **Hourly**: Incremental backup of chat_messages and message_reads
- **Real-time**: Transaction log backup for point-in-time recovery