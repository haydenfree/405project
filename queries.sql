
/*see user*/
select handle, fullname, location, email, bdate, joined from  Identity where idnum = 2 and not (exists (select 1 from Identity as x inner join Block as y on (x.idnum = y.blocked) where x.handle = "@snapoleon0" and y.idnum = 2));

/*new Story*/
insert into Story (idnum, chapter, url, expires) select a.idnum, "this is a test", "testurl.com", "2020/12/12 00:00:00" from Identity as a where a.handle = "@snapoleon0" and a.pass = "xZmN6L";

/*follow*/
insert into Follows (follower, followed) select a.idnum, 2 from Identity as a where (a.handle = "@snapoleon0" and a.pass = "xZmN6L") and not (exists (select x.followed from Identity as y inner join Follows as x on (y.idnum = x.follower and y.handle = "@snapoleon0" and x.followed = 2)));

/*suggestions*/
select s.idnum, s.handle from Identity as a inner join Follows as b on (a.idnum = b.follower) inner join Follows as c on (b.followed = c.follower) inner join Identity as s on (c.followed = s.idnum) where a.handle = "@snapoleon0" and a.pass = "xZmN6L" and s.handle != "@snapoleon0" and s.idnum not in (select x.followed from Identity as y inner join Follows as x on (y.idnum = x.follower and y.handle = "@snapoleon0")) LIMIT 4;

/*unfollow*/
delete from Follows where follower = (select a.idnum from Identity as a where a.handle = "@snapoleon0" and a.pass = "xZmN6L") and followed = 2;

/*Reprint*/
insert into Reprint (idnum, sidnum, likeit) select a.idnum, 27, true from Identity as a where a.handle = "@snapoleon0" and a.pass = "xZmN6L";

/*new user*/
insert into Identity (handle, pass, fullname, location, email, bdate, joined) values ("@coleterrell", "test123", "Cole Terrell", "Lexington", "cole.terrell@uky.edu", "1997/10/06", "2020/04/28");

/*block*/
insert into Block (idnum, blocked) select a.idnum, 2 from Identity as a where a.handle = "@snapoleon0" and a.pass = "xZmN6L" and not exists(select * from Identity as a inner join Block as b on (a.idnum = b.idnum and a.handle = "@snapoleon0" and b.blocked = 2));

/*isBlocked*/
select 1 from Identity as a inner join Block as b on (a.idnum = b.blocked) where a.idnum = 1 and b.idnum = 2;

/*timeline*/
select "story" as type, c.idnum as author, c.chapter as chapter, c.tstamp as posted from Identity as a inner join Follows as b on (a.idnum = b.follower) inner join Story as c on (b.followed = c.idnum) where a.handle = "@snapoleon0" UNION select "reprint", y.idnum, y.chapter, y.tstamp from Identity as q inner join Follows as x on (q.idnum = x.follower) inner join Reprint as t on (x.followed = t.idnum) inner join Story as y on (t.sidnum = y.sidnum) where q.handle = "@snapoleon0";
