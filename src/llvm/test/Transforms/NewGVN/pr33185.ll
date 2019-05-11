; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -newgvn -S %s | FileCheck %s

@a = local_unnamed_addr global i32 9, align 4
@.str4 = private unnamed_addr constant [6 x i8] c"D:%d\0A\00", align 1

define i32 @test1() local_unnamed_addr {
; CHECK-LABEL: @test1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP:%.*]] = load i32, i32* @a, align 4
; CHECK-NEXT:    [[CMP1_I:%.*]] = icmp ne i32 [[TMP]], 0
; CHECK-NEXT:    br label [[FOR_BODY_I:%.*]]
; CHECK:       for.body.i:
; CHECK-NEXT:    [[TMP1:%.*]] = phi i1 [ true, [[ENTRY:%.*]] ], [ false, [[COND_END_I:%.*]] ]
; CHECK-NEXT:    [[F_08_I:%.*]] = phi i32 [ 0, [[ENTRY]] ], [ [[INC_I:%.*]], [[COND_END_I]] ]
; CHECK-NEXT:    [[MUL_I:%.*]] = select i1 [[CMP1_I]], i32 [[F_08_I]], i32 0
; CHECK-NEXT:    br i1 [[TMP1]], label [[COND_END_I]], label [[COND_TRUE_I:%.*]]
; CHECK:       cond.true.i:
; CHECK-NEXT:    [[DIV_I:%.*]] = udiv i32 [[MUL_I]], [[F_08_I]]
; CHECK-NEXT:    br label [[COND_END_I]]
; CHECK:       cond.end.i:
; CHECK-NEXT:    [[COND_I:%.*]] = phi i32 [ [[DIV_I]], [[COND_TRUE_I]] ], [ 0, [[FOR_BODY_I]] ]
; CHECK-NEXT:    [[INC_I]] = add nuw nsw i32 [[F_08_I]], 1
; CHECK-NEXT:    [[EXITCOND_I:%.*]] = icmp eq i32 [[INC_I]], 4
; CHECK-NEXT:    br i1 [[EXITCOND_I]], label [[FN1_EXIT:%.*]], label [[FOR_BODY_I]]
; CHECK:       fn1.exit:
; CHECK-NEXT:    [[CALL4:%.*]] = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str4, i64 0, i64 0), i32 [[COND_I]])
; CHECK-NEXT:    ret i32 0
;
entry:
  %tmp = load i32, i32* @a, align 4
  %cmp1.i = icmp ne i32 %tmp, 0
  br label %for.body.i

for.body.i:
  %tmp1 = phi i1 [ true, %entry ], [ false, %cond.end.i ]
  %f.08.i = phi i32 [ 0, %entry ], [ %inc.i, %cond.end.i ]
  %mul.i = select i1 %cmp1.i, i32 %f.08.i, i32 0
  br i1 %tmp1, label %cond.end.i, label %cond.true.i

cond.true.i:
  ;; Ensure we don't replace this divide with a phi of ops that merges the wrong loop iteration value
  %div.i = udiv i32 %mul.i, %f.08.i
  br label %cond.end.i

cond.end.i:
  %cond.i = phi i32 [ %div.i, %cond.true.i ], [ 0, %for.body.i ]
  %inc.i = add nuw nsw i32 %f.08.i, 1
  %exitcond.i = icmp eq i32 %inc.i, 4
  br i1 %exitcond.i, label %fn1.exit, label %for.body.i

fn1.exit:
  %cond.i.lcssa = phi i32 [ %cond.i, %cond.end.i ]
  %call4= tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str4, i64 0, i64 0), i32 %cond.i.lcssa)
  ret i32 0
}

declare i32 @printf(i8* nocapture readonly, ...)

;; Variant of the above where we have made the udiv available in each predecessor with the wrong values.
;; In the entry block, it is always 0, so we don't try to create a leader there, only in %cond.end.i.
;; We should not create a phi of ops for it using these leaders.
;; A correct phi of ops for this udiv would be phi(0, 1), which we are not smart enough to figure out.
;; If we reuse the incorrect leaders, we will get phi(0, 0).
define i32 @test2() local_unnamed_addr {
; CHECK-LABEL: @test2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP:%.*]] = load i32, i32* @a, align 4
; CHECK-NEXT:    [[CMP1_I:%.*]] = icmp ne i32 [[TMP]], 0
; CHECK-NEXT:    br label [[FOR_BODY_I:%.*]]
; CHECK:       for.body.i:
; CHECK-NEXT:    [[TMP1:%.*]] = phi i1 [ true, [[ENTRY:%.*]] ], [ false, [[COND_END_I:%.*]] ]
; CHECK-NEXT:    [[F_08_I:%.*]] = phi i32 [ 0, [[ENTRY]] ], [ [[INC_I:%.*]], [[COND_END_I]] ]
; CHECK-NEXT:    [[MUL_I:%.*]] = select i1 [[CMP1_I]], i32 [[F_08_I]], i32 0
; CHECK-NEXT:    br i1 [[TMP1]], label [[COND_END_I]], label [[COND_TRUE_I:%.*]]
; CHECK:       cond.true.i:
; CHECK-NEXT:    [[DIV_I:%.*]] = udiv i32 [[MUL_I]], [[F_08_I]]
; CHECK-NEXT:    br label [[COND_END_I]]
; CHECK:       cond.end.i:
; CHECK-NEXT:    [[COND_I:%.*]] = phi i32 [ [[DIV_I]], [[COND_TRUE_I]] ], [ 0, [[FOR_BODY_I]] ]
; CHECK-NEXT:    [[INC_I]] = add nuw nsw i32 [[F_08_I]], 1
; CHECK-NEXT:    [[TEST:%.*]] = udiv i32 [[MUL_I]], [[INC_I]]
; CHECK-NEXT:    [[CALL5:%.*]] = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str4, i64 0, i64 0), i32 [[TEST]])
; CHECK-NEXT:    [[EXITCOND_I:%.*]] = icmp eq i32 [[INC_I]], 4
; CHECK-NEXT:    br i1 [[EXITCOND_I]], label [[FN1_EXIT:%.*]], label [[FOR_BODY_I]]
; CHECK:       fn1.exit:
; CHECK-NEXT:    [[CALL4:%.*]] = tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str4, i64 0, i64 0), i32 [[COND_I]])
; CHECK-NEXT:    ret i32 0
;
entry:
  %tmp = load i32, i32* @a, align 4
  %cmp1.i = icmp ne i32 %tmp, 0
  br label %for.body.i

for.body.i:
  %tmp1 = phi i1 [ true, %entry ], [ false, %cond.end.i ]
  %f.08.i = phi i32 [ 0, %entry ], [ %inc.i, %cond.end.i ]
  %mul.i = select i1 %cmp1.i, i32 %f.08.i, i32 0
  br i1 %tmp1, label %cond.end.i, label %cond.true.i

cond.true.i:
  ;; Ensure we don't replace this divide with a phi of ops that merges the wrong loop iteration value
  %div.i = udiv i32 %mul.i, %f.08.i
  br label %cond.end.i

cond.end.i:
  %cond.i = phi i32 [ %div.i, %cond.true.i ], [ 0, %for.body.i ]
  %inc.i = add nuw nsw i32 %f.08.i, 1
  %test = udiv i32 %mul.i, %inc.i
  %call5= tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str4, i64 0, i64 0), i32 %test)
  %exitcond.i = icmp eq i32 %inc.i, 4
  br i1 %exitcond.i, label %fn1.exit, label %for.body.i

fn1.exit:
  %cond.i.lcssa = phi i32 [ %cond.i, %cond.end.i ]
  %call4= tail call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([6 x i8], [6 x i8]* @.str4, i64 0, i64 0), i32 %cond.i.lcssa)
  ret i32 0
}


