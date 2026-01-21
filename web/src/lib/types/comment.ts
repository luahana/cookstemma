/**
 * Comment response DTO
 * Represents a single comment on a cooking log
 */
export interface Comment {
  publicId: string;
  content: string | null; // null if deleted
  creatorPublicId: string;
  creatorUsername: string;
  creatorProfileImageUrl: string | null;
  replyCount: number;
  likeCount: number;
  isLikedByCurrentUser: boolean | null; // null if not logged in
  isEdited: boolean;
  isDeleted: boolean;
  createdAt: string; // ISO date string
}

/**
 * Comment with preview replies
 * Used for top-level comment listing
 */
export interface CommentWithReplies {
  comment: Comment;
  replies: Comment[];
  hasMoreReplies: boolean;
}

/**
 * Create comment request
 */
export interface CreateCommentRequest {
  content: string;
}

/**
 * Paginated comments response
 */
export interface CommentsPage {
  content: CommentWithReplies[];
  totalElements: number;
  totalPages: number;
  number: number; // current page
  size: number;
  first: boolean;
  last: boolean;
}

/**
 * Paginated replies response
 */
export interface RepliesPage {
  content: Comment[];
  totalElements: number;
  totalPages: number;
  number: number; // current page
  size: number;
  first: boolean;
  last: boolean;
}
